import AppIntents

struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTodoIntent(),
            phrases: [
                "Add a todo in \(.applicationName)",
                "Create a todo in \(.applicationName)",
                "New todo in \(.applicationName)"
            ],
            shortTitle: "Add Todo",
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: ListTodosIntent(),
            phrases: [
                "Show my todos in \(.applicationName)",
                "List todos in \(.applicationName)",
                "What are my todos in \(.applicationName)"
            ],
            shortTitle: "List Todos",
            systemImageName: "list.bullet"
        )

        AppShortcut(
            intent: GetPendingCountIntent(),
            phrases: [
                "How many todos in \(.applicationName)",
                "Count todos in \(.applicationName)",
                "Pending todos in \(.applicationName)"
            ],
            shortTitle: "Pending Count",
            systemImageName: "number.circle"
        )

        AppShortcut(
            intent: CompleteTodoIntent(),
            phrases: [
                "Complete a todo in \(.applicationName)",
                "Mark todo done in \(.applicationName)"
            ],
            shortTitle: "Complete Todo",
            systemImageName: "checkmark.circle"
        )

        AppShortcut(
            intent: ClearCompletedIntent(),
            phrases: [
                "Clear completed todos in \(.applicationName)",
                "Remove done todos in \(.applicationName)",
                "Clean up \(.applicationName)"
            ],
            shortTitle: "Clear Completed",
            systemImageName: "trash"
        )
    }
}
