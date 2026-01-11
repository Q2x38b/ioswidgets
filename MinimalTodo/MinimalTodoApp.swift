import SwiftUI

@main
struct MinimalTodoApp: App {
    @StateObject private var store = TodoStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
