import Foundation

struct TodoItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, createdAt: Date = Date(), completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    mutating func toggle() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}

extension TodoItem {
    static let preview = TodoItem(title: "Buy groceries")
    static let previewCompleted = TodoItem(title: "Walk the dog", isCompleted: true, completedAt: Date())

    static let previewList: [TodoItem] = [
        TodoItem(title: "Buy groceries"),
        TodoItem(title: "Call mom"),
        TodoItem(title: "Finish project", isCompleted: true, completedAt: Date()),
        TodoItem(title: "Read book"),
        TodoItem(title: "Exercise", isCompleted: true, completedAt: Date())
    ]
}
