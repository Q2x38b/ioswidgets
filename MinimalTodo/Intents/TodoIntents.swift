import AppIntents
import Foundation
import WidgetKit

// MARK: - Todo Entity for Shortcuts

struct TodoEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Todo"
    static var defaultQuery = TodoQuery()

    var id: UUID
    var title: String
    var isCompleted: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: isCompleted ? "Completed" : "Pending",
            image: .init(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
        )
    }

    init(id: UUID, title: String, isCompleted: Bool) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }

    init(from item: TodoItem) {
        self.id = item.id
        self.title = item.title
        self.isCompleted = item.isCompleted
    }
}

struct TodoQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [TodoEntity] {
        let items = TodoStore.loadItems()
        return items
            .filter { identifiers.contains($0.id) }
            .map { TodoEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [TodoEntity] {
        let items = TodoStore.loadItems()
        return items.map { TodoEntity(from: $0) }
    }
}

// MARK: - Add Todo Intent

struct AddTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Todo"
    static var description = IntentDescription("Add a new todo item to your list")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Title", description: "What needs to be done?")
    var title: String

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$title) to todos")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<TodoEntity> & ProvidesDialog {
        let item = TodoStore.addItem(title: title)
        let entity = TodoEntity(from: item)

        return .result(
            value: entity,
            dialog: "Added '\(title)' to your todos"
        )
    }
}

// MARK: - Complete Todo Intent

struct CompleteTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Todo"
    static var description = IntentDescription("Mark a todo as completed")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Todo")
    var todo: TodoEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Complete \(\.$todo)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let item = TodoStore.completeItem(id: todo.id) else {
            return .result(dialog: "Todo not found")
        }

        if item.isCompleted {
            return .result(dialog: "Completed '\(item.title)'")
        } else {
            return .result(dialog: "'\(item.title)' was already completed")
        }
    }
}

// MARK: - Toggle Todo Intent

struct ToggleTodoAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Todo"
    static var description = IntentDescription("Toggle a todo's completion status")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Todo")
    var todo: TodoEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Toggle \(\.$todo)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<TodoEntity> & ProvidesDialog {
        guard let item = TodoStore.toggleItem(id: todo.id) else {
            throw TodoIntentError.notFound
        }

        let entity = TodoEntity(from: item)
        let status = item.isCompleted ? "completed" : "incomplete"

        return .result(
            value: entity,
            dialog: "Marked '\(item.title)' as \(status)"
        )
    }
}

// MARK: - Delete Todo Intent

struct DeleteTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Delete Todo"
    static var description = IntentDescription("Delete a todo from your list")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Todo")
    var todo: TodoEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Delete \(\.$todo)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let title = todo.title
        let success = TodoStore.deleteItem(id: todo.id)

        if success {
            return .result(dialog: "Deleted '\(title)'")
        } else {
            return .result(dialog: "Todo not found")
        }
    }
}

// MARK: - List Todos Intent

struct ListTodosIntent: AppIntent {
    static var title: LocalizedStringResource = "List Todos"
    static var description = IntentDescription("Get all your todos")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Filter", default: .pending)
    var filter: TodoFilterType

    enum TodoFilterType: String, AppEnum {
        case all = "All"
        case pending = "Pending"
        case completed = "Completed"

        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Filter"
        static var caseDisplayRepresentations: [TodoFilterType: DisplayRepresentation] = [
            .all: "All",
            .pending: "Pending",
            .completed: "Completed"
        ]
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Get \(\.$filter) todos")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<[TodoEntity]> & ProvidesDialog {
        let items = TodoStore.loadItems()
        let filtered: [TodoItem]

        switch filter {
        case .all:
            filtered = items
        case .pending:
            filtered = items.filter { !$0.isCompleted }
        case .completed:
            filtered = items.filter { $0.isCompleted }
        }

        let entities = filtered.map { TodoEntity(from: $0) }
        let count = entities.count

        let dialog: String
        switch filter {
        case .all:
            dialog = "You have \(count) todo\(count == 1 ? "" : "s")"
        case .pending:
            dialog = "You have \(count) pending todo\(count == 1 ? "" : "s")"
        case .completed:
            dialog = "You have \(count) completed todo\(count == 1 ? "" : "s")"
        }

        return .result(value: entities, dialog: "\(dialog)")
    }
}

// MARK: - Get Pending Count Intent

struct GetPendingCountIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Pending Todo Count"
    static var description = IntentDescription("Get the number of incomplete todos")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        let items = TodoStore.loadItems()
        let pendingCount = items.filter { !$0.isCompleted }.count

        let dialog = pendingCount == 0
            ? "All done! No pending todos"
            : "You have \(pendingCount) pending todo\(pendingCount == 1 ? "" : "s")"

        return .result(value: pendingCount, dialog: "\(dialog)")
    }
}

// MARK: - Clear Completed Intent

struct ClearCompletedIntent: AppIntent {
    static var title: LocalizedStringResource = "Clear Completed Todos"
    static var description = IntentDescription("Remove all completed todos from your list")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        var items = TodoStore.loadItems()
        let completedCount = items.filter { $0.isCompleted }.count
        items.removeAll { $0.isCompleted }
        TodoStore.saveItems(items)

        let dialog = completedCount == 0
            ? "No completed todos to clear"
            : "Cleared \(completedCount) completed todo\(completedCount == 1 ? "" : "s")"

        return .result(dialog: "\(dialog)")
    }
}

// MARK: - Errors

enum TodoIntentError: Error, CustomLocalizedStringResourceConvertible {
    case notFound
    case invalidTitle

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notFound:
            return "Todo not found"
        case .invalidTitle:
            return "Invalid todo title"
        }
    }
}
