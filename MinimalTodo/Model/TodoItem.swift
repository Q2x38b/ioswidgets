import Foundation

enum TaskPriority: String, Codable, CaseIterable {
    case none
    case low
    case medium
    case high
}

enum TaskColor: String, Codable, CaseIterable {
    case grey
    case rose
    case purple
    case amber
    case sky
    case emerald

    var displayName: String {
        switch self {
        case .grey: return "Gray"
        case .rose: return "Pink"
        case .purple: return "Purple"
        case .amber: return "Orange"
        case .sky: return "Blue"
        case .emerald: return "Green"
        }
    }
}

struct TodoItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?

    // Enhanced properties from stride
    var dueDate: Date?
    var startTime: String?
    var endTime: String?
    var color: TaskColor
    var priority: TaskPriority
    var status: String
    var customTags: [String]
    var subtasks: [String]
    var order: Int
    var recurring: String
    var reminder: String?
    var duration: Int
    var location: String

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        dueDate: Date? = nil,
        startTime: String? = nil,
        endTime: String? = nil,
        color: TaskColor = .grey,
        priority: TaskPriority = .none,
        status: String = "",
        customTags: [String] = [],
        subtasks: [String] = [],
        order: Int = 0,
        recurring: String = "",
        reminder: String? = nil,
        duration: Int = 0,
        location: String = ""
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.startTime = startTime
        self.endTime = endTime
        self.color = color
        self.priority = priority
        self.status = status
        self.customTags = customTags
        self.subtasks = subtasks
        self.order = order
        self.recurring = recurring
        self.reminder = reminder
        self.duration = duration
        self.location = location
    }

    mutating func toggle() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }

    // MARK: - Codable Migration Support

    enum CodingKeys: String, CodingKey {
        case id, title, description, isCompleted, createdAt, completedAt
        case dueDate, startTime, endTime, color, priority, status
        case customTags, subtasks, order, recurring, reminder, duration, location
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required fields
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        createdAt = try container.decode(Date.self, forKey: .createdAt)

        // Optional fields with defaults for backward compatibility
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        startTime = try container.decodeIfPresent(String.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(String.self, forKey: .endTime)
        color = try container.decodeIfPresent(TaskColor.self, forKey: .color) ?? .grey
        priority = try container.decodeIfPresent(TaskPriority.self, forKey: .priority) ?? .none
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        customTags = try container.decodeIfPresent([String].self, forKey: .customTags) ?? []
        subtasks = try container.decodeIfPresent([String].self, forKey: .subtasks) ?? []
        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        recurring = try container.decodeIfPresent(String.self, forKey: .recurring) ?? ""
        reminder = try container.decodeIfPresent(String.self, forKey: .reminder)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration) ?? 0
        location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
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
