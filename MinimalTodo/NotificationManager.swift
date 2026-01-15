import Foundation
import UserNotifications
import CoreLocation

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            checkAuthorizationStatus()

            if granted {
                locationManager.requestWhenInUseAuthorization()
            }

            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    // MARK: - Time-Based Reminders

    func scheduleTimeReminder(for item: TodoItem, minutesBefore: Int = 15) {
        guard let dueDate = item.dueDate else { return }

        let reminderDate = Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: dueDate) ?? dueDate

        // Only schedule if the reminder time is in the future
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = item.title
        content.sound = .default
        content.badge = 1
        content.userInfo = ["taskId": item.id.uuidString]

        // Add time info if available
        if let startTime = item.startTime {
            content.subtitle = "Due at \(startTime)"
        }

        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(identifier: "task-\(item.id.uuidString)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("✅ Scheduled reminder for \(item.title) at \(reminderDate)")
            }
        }
    }

    func cancelTimeReminder(for item: TodoItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["task-\(item.id.uuidString)"])
    }

    // MARK: - Location-Based Reminders

    func scheduleLocationReminder(for item: TodoItem, location: CLLocationCoordinate2D, radius: Double = 100) {
        guard item.location.isEmpty == false else { return }

        let content = UNMutableNotificationContent()
        content.title = "Location Reminder"
        content.body = item.title
        content.sound = .default
        content.badge = 1
        content.userInfo = ["taskId": item.id.uuidString, "location": item.location]

        if let startTime = item.startTime {
            content.subtitle = "Scheduled for \(startTime)"
        }

        // Create circular region for geofencing
        let region = CLCircularRegion(
            center: location,
            radius: radius,
            identifier: "task-location-\(item.id.uuidString)"
        )
        region.notifyOnEntry = true
        region.notifyOnExit = false

        let trigger = UNLocationNotificationTrigger(region: region, repeats: false)
        let request = UNNotificationRequest(
            identifier: "task-location-\(item.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling location notification: \(error)")
            } else {
                print("✅ Scheduled location reminder for \(item.title)")
            }
        }
    }

    func cancelLocationReminder(for item: TodoItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["task-location-\(item.id.uuidString)"])
    }

    // MARK: - Batch Operations

    func scheduleAllReminders(for items: [TodoItem], defaultMinutesBefore: Int = 15) {
        for item in items where !item.isCompleted {
            // Schedule time-based reminders
            if item.dueDate != nil {
                scheduleTimeReminder(for: item, minutesBefore: defaultMinutesBefore)
            }
        }
    }

    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("✅ Cancelled all pending reminders")
    }

    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
}

// MARK: - CLLocationManagerDelegate

extension NotificationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            print("Location authorization status: \(status.rawValue)")
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
}

// MARK: - Helper for Geocoding

extension NotificationManager {
    func geocodeLocation(_ locationString: String) async -> CLLocationCoordinate2D? {
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.geocodeAddressString(locationString)
            return placemarks.first?.location?.coordinate
        } catch {
            print("Geocoding error: \(error)")
            return nil
        }
    }
}
