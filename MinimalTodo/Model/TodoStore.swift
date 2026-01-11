import Foundation
import SwiftUI
import WidgetKit

@MainActor
class TodoStore: ObservableObject {
    @Published private(set) var items: [TodoItem] = []

    private static let appGroupIdentifier = "group.com.minimaltodo.app"
    private static let todosKey = "todos"

    static let shared = TodoStore()

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupIdentifier)
    }

    init() {
        load()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = userDefaults?.data(forKey: Self.todosKey),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return
        }
        items = decoded
    }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(items) else { return }
        userDefaults?.set(encoded, forKey: Self.todosKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - CRUD Operations

    func add(_ title: String) -> TodoItem {
        let item = TodoItem(title: title)
        items.insert(item, at: 0)
        save()
        return item
    }

    func toggle(_ item: TodoItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].toggle()
        save()
    }

    func toggleById(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].toggle()
        save()
    }

    func delete(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func deleteById(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func deleteCompleted() {
        items.removeAll { $0.isCompleted }
        save()
    }

    func update(_ item: TodoItem, title: String) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].title = title
        save()
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
    static func loadItems() -> [TodoItem] {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = userDefaults.data(forKey: todosKey),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return []
        }
        return decoded
    }

    static func saveItems(_ items: [TodoItem]) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let encoded = try? JSONEncoder().encode(items) else { return }
        userDefaults.set(encoded, forKey: todosKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func addItem(title: String) -> TodoItem {
        var items = loadItems()
        let item = TodoItem(title: title)
        items.insert(item, at: 0)
        saveItems(items)
        return item
    }

    static func toggleItem(id: UUID) -> TodoItem? {
        var items = loadItems()
        guard let index = items.firstIndex(where: { $0.id == id }) else { return nil }
        items[index].toggle()
        saveItems(items)
        return items[index]
    }

    static func deleteItem(id: UUID) -> Bool {
        var items = loadItems()
        let initialCount = items.count
        items.removeAll { $0.id == id }
        if items.count < initialCount {
            saveItems(items)
            return true
        }
        return false
    }

    static func completeItem(id: UUID) -> TodoItem? {
        var items = loadItems()
        guard let index = items.firstIndex(where: { $0.id == id }) else { return nil }
        if !items[index].isCompleted {
            items[index].toggle()
            saveItems(items)
        }
        return items[index]
    }
}
