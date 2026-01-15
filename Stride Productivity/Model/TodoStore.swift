import Foundation
import SwiftUI
import WidgetKit

@MainActor
class TodoStore: ObservableObject {
    @Published private(set) var items: [TodoItem] = []
    @Published var isLoading = false
    @Published var syncError: Error?

    nonisolated private static let appGroupIdentifier = "group.com.strideproductivity.app"
    nonisolated private static let todosKey = "todos"
    nonisolated private static let convexMapKey = "convexIdMap"

    static let shared = TodoStore()

    // Map local UUIDs to Convex document IDs
    private var convexIdMap: [UUID: String] = [:]

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupIdentifier)
    }

    init() {
        // Load cached items for immediate display
        loadFromCache()
    }

    // MARK: - Sync with Convex Backend

    func syncWithBackend() async {
        #if !WIDGET_EXTENSION
        guard let userId = AuthManager.shared.userId else {
            // Not signed in, clear items
            items = []
            saveToCache()
            return
        }

        isLoading = true
        syncError = nil

        do {
            let tasks = try await ConvexClient.shared.listTasks(userId: userId)

            // Update local items from Convex
            items = tasks.map { $0.toTodoItem() }

            // Update the ID map
            convexIdMap = Dictionary(uniqueKeysWithValues: tasks.compactMap { task -> (UUID, String)? in
                guard let uuid = UUID(uuidString: task._id) else { return nil }
                return (uuid, task._id)
            })

            // Cache for offline access
            saveToCache()

        } catch {
            syncError = error
            print("Sync error: \(error)")
            // Fall back to cached data
            loadFromCache()
        }

        isLoading = false
        #else
        loadFromCache()
        #endif
    }

    // MARK: - Local Cache (for offline support and widgets)

    private func loadFromCache() {
        guard let data = userDefaults?.data(forKey: Self.todosKey),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return
        }
        items = decoded

        // Load convex ID map
        if let mapData = userDefaults?.data(forKey: Self.convexMapKey),
           let map = try? JSONDecoder().decode([String: String].self, from: mapData) {
            convexIdMap = Dictionary(uniqueKeysWithValues: map.compactMap {
                guard let uuid = UUID(uuidString: $0.key) else { return nil }
                return (uuid, $0.value)
            })
        }
    }

    private func saveToCache() {
        guard let encoded = try? JSONEncoder().encode(items) else { return }
        userDefaults?.set(encoded, forKey: Self.todosKey)

        // Save convex ID map
        let mapToSave = Dictionary(uniqueKeysWithValues: convexIdMap.map { ($0.key.uuidString, $0.value) })
        if let mapData = try? JSONEncoder().encode(mapToSave) {
            userDefaults?.set(mapData, forKey: Self.convexMapKey)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    func reload() {
        Task {
            await syncWithBackend()
        }
    }

    // MARK: - CRUD Operations

    @discardableResult
    func add(_ title: String) -> TodoItem {
        let item = TodoItem(title: title, dueDate: Date(), order: items.count)
        items.insert(item, at: 0)
        saveToCache()

        #if !WIDGET_EXTENSION
        // Sync to Convex
        Task {
            await createOnBackend(item)
        }
        #endif

        return item
    }

    @discardableResult
    func add(_ item: TodoItem) -> TodoItem {
        items.insert(item, at: 0)
        reorderIfNeeded()
        saveToCache()

        #if !WIDGET_EXTENSION
        // Sync to Convex
        Task {
            await createOnBackend(item)
        }
        #endif

        return item
    }

    #if !WIDGET_EXTENSION
    private func createOnBackend(_ item: TodoItem) async {
        guard let userId = AuthManager.shared.userId else { return }

        do {
            let convexId = try await ConvexClient.shared.createTask(userId: userId, item: item)
            convexIdMap[item.id] = convexId
            saveToCache()
        } catch {
            print("Failed to create task on backend: \(error)")
            syncError = error
        }
    }
    #endif

    func toggle(_ item: TodoItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].toggle()
        saveToCache()

        #if !WIDGET_EXTENSION
        // Sync to Convex
        Task {
            await toggleOnBackend(item.id)
        }
        #endif
    }

    func toggleById(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].toggle()
        saveToCache()

        #if !WIDGET_EXTENSION
        // Sync to Convex
        Task {
            await toggleOnBackend(id)
        }
        #endif
    }

    #if !WIDGET_EXTENSION
    private func toggleOnBackend(_ id: UUID) async {
        guard let convexId = convexIdMap[id] else { return }

        do {
            try await ConvexClient.shared.toggleTask(taskId: convexId)
        } catch {
            print("Failed to toggle task on backend: \(error)")
            syncError = error
        }
    }
    #endif

    func delete(_ item: TodoItem) {
        let id = item.id
        items.removeAll { $0.id == id }
        saveToCache()

        #if !WIDGET_EXTENSION
        // Sync to Convex
        Task {
            await deleteOnBackend(id)
        }
        #endif
    }

    func deleteById(_ id: UUID) {
        items.removeAll { $0.id == id }
        saveToCache()

        #if !WIDGET_EXTENSION
        // Sync to Convex
        Task {
            await deleteOnBackend(id)
        }
        #endif
    }

    #if !WIDGET_EXTENSION
    private func deleteOnBackend(_ id: UUID) async {
        guard let convexId = convexIdMap[id] else { return }

        do {
            try await ConvexClient.shared.deleteTask(taskId: convexId)
            convexIdMap.removeValue(forKey: id)
            saveToCache()
        } catch {
            print("Failed to delete task on backend: \(error)")
            syncError = error
        }
    }
    #endif

    func deleteCompleted() {
        let completedIds = items.filter { $0.isCompleted }.map { $0.id }
        items.removeAll { $0.isCompleted }
        saveToCache()

        #if !WIDGET_EXTENSION
        // Sync to Convex
        Task {
            guard let userId = AuthManager.shared.userId else { return }
            do {
                _ = try await ConvexClient.shared.deleteCompletedTasks(userId: userId)
                for id in completedIds {
                    convexIdMap.removeValue(forKey: id)
                }
                saveToCache()
            } catch {
                print("Failed to delete completed tasks: \(error)")
            }
        }
        #endif
    }

    func update(_ item: TodoItem, title: String) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].title = title
        saveToCache()

        #if !WIDGET_EXTENSION
        // Sync to Convex
        Task {
            await updateOnBackend(item.id, updates: ["title": title])
        }
        #endif
    }

    func update(_ id: UUID, with updates: (inout TodoItem) -> Void) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let oldItem = items[index]
        updates(&items[index])
        reorderIfNeeded()
        saveToCache()

        #if !WIDGET_EXTENSION
        // Build update dictionary
        let newItem = items[index]
        var updateDict: [String: Any] = [:]

        if newItem.title != oldItem.title { updateDict["title"] = newItem.title }
        if newItem.description != oldItem.description { updateDict["description"] = newItem.description }
        if newItem.isCompleted != oldItem.isCompleted { updateDict["isCompleted"] = newItem.isCompleted }
        if newItem.color != oldItem.color { updateDict["color"] = newItem.color.rawValue }
        if newItem.priority != oldItem.priority { updateDict["priority"] = newItem.priority.rawValue }
        if newItem.startTime != oldItem.startTime { updateDict["startTime"] = newItem.startTime as Any }
        if newItem.endTime != oldItem.endTime { updateDict["endTime"] = newItem.endTime as Any }
        if newItem.location != oldItem.location { updateDict["location"] = newItem.location }
        if let dueDate = newItem.dueDate {
            updateDict["dueDate"] = dueDate.timeIntervalSince1970 * 1000
        }

        if !updateDict.isEmpty {
            Task {
                await updateOnBackend(id, updates: updateDict)
            }
        }
        #endif
    }

    #if !WIDGET_EXTENSION
    private func updateOnBackend(_ id: UUID, updates: [String: Any]) async {
        guard let convexId = convexIdMap[id] else { return }

        do {
            try await ConvexClient.shared.updateTask(taskId: convexId, updates: updates)
        } catch {
            print("Failed to update task on backend: \(error)")
            syncError = error
        }
    }
    #endif

    // MARK: - Sorting

    private func reorderIfNeeded() {
        items.sort { item1, item2 in
            let time1 = item1.startTime ?? ""
            let time2 = item2.startTime ?? ""

            if !time1.isEmpty && !time2.isEmpty {
                return time1 < time2
            }
            if !time1.isEmpty && time2.isEmpty {
                return true
            }
            if time1.isEmpty && !time2.isEmpty {
                return false
            }
            return item1.order < item2.order
        }
    }

    func sortedItems(for date: Date) -> [TodoItem] {
        let calendar = Calendar.current
        return items.filter { item in
            guard let dueDate = item.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }.sorted { item1, item2 in
            let time1 = item1.startTime ?? ""
            let time2 = item2.startTime ?? ""

            if !time1.isEmpty && !time2.isEmpty {
                return time1 < time2
            }
            if !time1.isEmpty && time2.isEmpty {
                return true
            }
            if time1.isEmpty && !time2.isEmpty {
                return false
            }
            return item1.order < item2.order
        }
    }

    // MARK: - Queries

    var pendingItems: [TodoItem] {
        items.filter { !$0.isCompleted }
    }

    var completedItems: [TodoItem] {
        items.filter { $0.isCompleted }
    }

    var pendingCount: Int {
        pendingItems.count
    }

    func item(withId id: UUID) -> TodoItem? {
        items.first { $0.id == id }
    }
}

// MARK: - Static access for widgets and intents

extension TodoStore {
    nonisolated static func loadItems() -> [TodoItem] {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = userDefaults.data(forKey: todosKey),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return []
        }
        return decoded
    }

    nonisolated static func saveItems(_ items: [TodoItem]) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let encoded = try? JSONEncoder().encode(items) else { return }
        userDefaults.set(encoded, forKey: todosKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    nonisolated static func addItem(title: String) -> TodoItem {
        var items = loadItems()
        let item = TodoItem(title: title, dueDate: Date())
        items.insert(item, at: 0)
        saveItems(items)
        return item
    }

    nonisolated static func toggleItem(id: UUID) -> TodoItem? {
        var items = loadItems()
        guard let index = items.firstIndex(where: { $0.id == id }) else { return nil }
        items[index].toggle()
        saveItems(items)
        return items[index]
    }

    nonisolated static func deleteItem(id: UUID) -> Bool {
        var items = loadItems()
        let initialCount = items.count
        items.removeAll { $0.id == id }
        if items.count < initialCount {
            saveItems(items)
            return true
        }
        return false
    }

    nonisolated static func completeItem(id: UUID) -> TodoItem? {
        var items = loadItems()
        guard let index = items.firstIndex(where: { $0.id == id }) else { return nil }
        if !items[index].isCompleted {
            items[index].toggle()
            saveItems(items)
        }
        return items[index]
    }
}
