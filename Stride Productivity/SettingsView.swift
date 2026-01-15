import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var store: TodoStore
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("locationRemindersEnabled") private var locationRemindersEnabled = false
    @AppStorage("defaultReminderTime") private var defaultReminderTime = 30
    @State private var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { oldValue, newValue in
                            if newValue {
                                requestNotificationPermission()
                            }
                        }

                    if notificationsEnabled {
                        Picker("Default Reminder", selection: $defaultReminderTime) {
                            Text("5 minutes").tag(5)
                            Text("15 minutes").tag(15)
                            Text("30 minutes").tag(30)
                            Text("1 hour").tag(60)
                            Text("1 day").tag(1440)
                        }

                        Toggle("Location-Based Reminders", isOn: $locationRemindersEnabled)
                    }
                }

                Section("Sync") {
                    HStack {
                        Text("Cloud Sync")
                        Spacer()
                        Text("Local storage")
                            .foregroundStyle(.secondary)
                    }

                    if store.isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                            Text("Loading...")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Button("Refresh") {
                            store.reload()
                        }
                        .foregroundStyle(Color.appAccent)
                    }
                }

                Section("Data") {
                    Button("Clear Completed Tasks") {
                        withAnimation {
                            store.deleteCompleted()
                        }
                    }
                    .foregroundStyle(Color.appAccent)
                    .disabled(store.completedItems.isEmpty)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Tasks")
                        Spacer()
                        Text("\(store.items.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Pending")
                        Spacer()
                        Text("\(store.pendingCount)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                checkNotificationPermission()
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    notificationPermissionStatus = .authorized
                } else {
                    notificationPermissionStatus = .denied
                    notificationsEnabled = false
                }
            }
        }
    }

    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermissionStatus = settings.authorizationStatus
                if settings.authorizationStatus != .authorized {
                    notificationsEnabled = false
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(TodoStore.shared)
}
