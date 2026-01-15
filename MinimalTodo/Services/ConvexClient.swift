import Foundation

// MARK: - Convex Configuration
struct ConvexConfig {
    // Replace with your actual Convex deployment URL
    static let deploymentURL = "https://YOUR_CONVEX_DEPLOYMENT.convex.cloud"

    // API endpoints
    static var queryURL: URL { URL(string: "\(deploymentURL)/api/query")! }
    static var mutationURL: URL { URL(string: "\(deploymentURL)/api/mutation")! }
}

// MARK: - Convex Task Model (matches schema)
struct ConvexTask: Codable, Identifiable {
    let _id: String
    let userId: String
    let title: String
    let description: String
    let isCompleted: Bool
    let createdAt: Double
    let completedAt: Double?
    let dueDate: Double?
    let startTime: String?
    let endTime: String?
    let color: String
    let priority: String
    let status: String
    let customTags: [String]
    let subtasks: [String]
    let order: Int
    let recurring: String
    let reminder: String?
    let duration: Int
    let location: String

    var id: String { _id }

    // Convert to local TodoItem
    func toTodoItem() -> TodoItem {
        TodoItem(
            id: UUID(uuidString: _id) ?? UUID(),
            title: title,
            description: description,
            isCompleted: isCompleted,
            createdAt: Date(timeIntervalSince1970: createdAt / 1000),
            completedAt: completedAt.map { Date(timeIntervalSince1970: $0 / 1000) },
            dueDate: dueDate.map { Date(timeIntervalSince1970: $0 / 1000) },
            startTime: startTime,
            endTime: endTime,
            color: TaskColor(rawValue: color) ?? .grey,
            priority: TaskPriority(rawValue: priority) ?? .none,
            status: status,
            customTags: customTags,
            subtasks: subtasks,
            order: order,
            recurring: recurring,
            reminder: reminder,
            duration: duration,
            location: location
        )
    }
}

// MARK: - Convex Client
@MainActor
class ConvexClient: ObservableObject {
    static let shared = ConvexClient()

    @Published var isConnected = false
    @Published var error: Error?

    private var authToken: String?
    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private init() {}

    func setAuthToken(_ token: String?) {
        self.authToken = token
        self.isConnected = token != nil
    }

    // MARK: - Query Methods

    func listTasks(userId: String) async throws -> [ConvexTask] {
        let response: ConvexQueryResponse<[ConvexTask]> = try await query(
            path: "tasks:list",
            args: ["userId": userId]
        )
        return response.value
    }

    func listTasksByDate(userId: String, date: Date) async throws -> [ConvexTask] {
        let response: ConvexQueryResponse<[ConvexTask]> = try await query(
            path: "tasks:listByDate",
            args: ["userId": userId, "dueDate": date.timeIntervalSince1970 * 1000]
        )
        return response.value
    }

    // MARK: - Mutation Methods

    func createTask(userId: String, item: TodoItem) async throws -> String {
        var args: [String: Any] = [
            "userId": userId,
            "title": item.title,
            "description": item.description,
            "color": item.color.rawValue,
            "priority": item.priority.rawValue,
            "status": item.status,
            "customTags": item.customTags,
            "subtasks": item.subtasks,
            "order": item.order,
            "recurring": item.recurring,
            "duration": item.duration,
            "location": item.location
        ]

        if let dueDate = item.dueDate {
            args["dueDate"] = dueDate.timeIntervalSince1970 * 1000
        }
        if let startTime = item.startTime {
            args["startTime"] = startTime
        }
        if let endTime = item.endTime {
            args["endTime"] = endTime
        }
        if let reminder = item.reminder {
            args["reminder"] = reminder
        }

        let response: ConvexMutationResponse<String> = try await mutation(
            path: "tasks:create",
            args: args
        )
        return response.value
    }

    func updateTask(taskId: String, updates: [String: Any]) async throws {
        var args = updates
        args["id"] = taskId

        let _: ConvexMutationResponse<String> = try await mutation(
            path: "tasks:update",
            args: args
        )
    }

    func toggleTask(taskId: String) async throws {
        let _: ConvexMutationResponse<String> = try await mutation(
            path: "tasks:toggle",
            args: ["id": taskId]
        )
    }

    func deleteTask(taskId: String) async throws {
        let _: ConvexMutationResponse<String?> = try await mutation(
            path: "tasks:remove",
            args: ["id": taskId]
        )
    }

    func deleteCompletedTasks(userId: String) async throws -> Int {
        let response: ConvexMutationResponse<Int> = try await mutation(
            path: "tasks:removeCompleted",
            args: ["userId": userId]
        )
        return response.value
    }

    // MARK: - Private Methods

    private func query<T: Decodable>(path: String, args: [String: Any]) async throws -> T {
        var request = URLRequest(url: ConvexConfig.queryURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "path": path,
            "args": args,
            "format": "json"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ConvexError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ConvexError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return try decoder.decode(T.self, from: data)
    }

    private func mutation<T: Decodable>(path: String, args: [String: Any]) async throws -> T {
        var request = URLRequest(url: ConvexConfig.mutationURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "path": path,
            "args": args,
            "format": "json"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ConvexError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ConvexError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Response Types

struct ConvexQueryResponse<T: Decodable>: Decodable {
    let value: T
    let status: String?
}

struct ConvexMutationResponse<T: Decodable>: Decodable {
    let value: T
    let status: String?
}

// MARK: - Errors

enum ConvexError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .notAuthenticated:
            return "Not authenticated"
        }
    }
}
