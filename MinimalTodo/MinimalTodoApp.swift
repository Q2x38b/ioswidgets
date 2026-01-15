import SwiftUI

@main
struct StrideApp: App {
    @StateObject private var store = TodoStore.shared
    @StateObject private var authManager = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                switch authManager.authState {
                case .loading:
                    // Show loading screen
                    ZStack {
                        Color(.systemBackground)
                        VStack(spacing: 16) {
                            Image(systemName: "calendar")
                                .font(.system(size: 60, weight: .bold))
                                .foregroundStyle(Color.appAccent)
                            Text("Stride")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            ProgressView()
                        }
                    }
                    .ignoresSafeArea()

                case .signedOut:
                    // Show auth view
                    AuthView()

                case .signedIn:
                    // Show main content
                    ContentView()
                        .environmentObject(store)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
