//
//  RemoteNotificationService.swift
//  MoodGpt
//
//  Handles remote notifications and server-initiated notifications
//

import Foundation
import UserNotifications
import SwiftUI

// MARK: - Server Notification Model
struct ServerNotification: Codable {
    let id: Int
    let message: String
    let timestamp: String
}

// MARK: - Remote Notification Service
class RemoteNotificationService: NSObject, ObservableObject {
    static let shared = RemoteNotificationService()
    
    @Published var lastNotification: NotificationData?
    @Published var notificationHistory: [NotificationData] = []
    @Published var isPolling = false
    
    private var pollTimer: Timer?
    private var lastProcessedId: Int = 0
    private let notificationAPIURL = "https://notification-inky.vercel.app/notifications"
    
    struct NotificationData: Identifiable, Codable {
        let id = UUID()
        let serverId: Int
        let title: String
        let body: String
        let timestamp: Date
        let type: String? = "server"
        let data: [String: String]? = nil
    }
    
    override init() {
        super.init()
        loadLastProcessedId()
        loadNotificationHistory()
    }
    
    // MARK: - Polling for Remote Notifications
    
    func startPollingForNotifications() {
        guard !isPolling else { return }
        
        isPolling = true
        
        // Poll every 2 seconds
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task {
                await self.checkForRemoteNotifications()
            }
        }
        
        // Check immediately
        Task {
            await checkForRemoteNotifications()
        }
    }
    
    func stopPollingForNotifications() {
        pollTimer?.invalidate()
        pollTimer = nil
        isPolling = false
    }
    
    // Check server for new notifications
    private func checkForRemoteNotifications() async {
        do {
            // Fetch notifications from API
            guard let url = URL(string: notificationAPIURL) else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Decode notifications
            let notifications = try JSONDecoder().decode([ServerNotification].self, from: data)
            
            // Process only new notifications (higher ID than last processed)
            let newNotifications = notifications.filter { $0.id > lastProcessedId }
                .sorted { $0.id < $1.id } // Process in order
            
            // Schedule each new notification
            for notification in newNotifications {
                // Parse the timestamp
                let dateFormatter = ISO8601DateFormatter()
                let notificationDate = dateFormatter.date(from: notification.timestamp) ?? Date()
                
                // Create notification immediately
                await scheduleNotification(
                    serverId: notification.id,
                    title: "MoodGpt Alert",
                    body: notification.message,
                    timestamp: notificationDate
                )
                
                // Update last processed ID
                lastProcessedId = notification.id
                saveLastProcessedId()
            }
            
        } catch {
            print("Failed to check for notifications: \(error)")
        }
    }
    
    // MARK: - Notification Handling
    
    private func scheduleNotification(serverId: Int, title: String, body: String, timestamp: Date) async {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        // Create trigger (immediate delivery)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        // Create request
        let requestID = "server-\(serverId)-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
        
        // Schedule notification
        do {
            try await UNUserNotificationCenter.current().add(request)
            
            // Save to history
            let notificationData = NotificationData(
                serverId: serverId,
                title: title,
                body: body,
                timestamp: timestamp
            )
            
            await MainActor.run {
                self.lastNotification = notificationData
                self.notificationHistory.insert(notificationData, at: 0) // Add to beginning
                
                // Keep only last 50 notifications
                if self.notificationHistory.count > 50 {
                    self.notificationHistory = Array(self.notificationHistory.prefix(50))
                }
                
                self.saveNotificationHistory()
                
                // Post notification for UI updates
                NotificationCenter.default.post(
                    name: NSNotification.Name("NewRemoteNotification"),
                    object: notificationData
                )
            }
            
            print("Remote notification scheduled: \(body)")
        } catch {
            print("Failed to schedule remote notification: \(error)")
        }
    }
    
    // MARK: - Direct Send Methods (For testing)
    
    func sendTestNotification() async {
        let testId = Int.random(in: 10000...99999)
        await scheduleNotification(
            serverId: testId,
            title: "Test Notification",
            body: "This is a test notification at \(Date())",
            timestamp: Date()
        )
    }
    
    // MARK: - Persistence
    
    private func saveNotificationHistory() {
        if let encoded = try? JSONEncoder().encode(notificationHistory) {
            UserDefaults.standard.set(encoded, forKey: "notification_history")
        }
    }
    
    private func loadNotificationHistory() {
        if let data = UserDefaults.standard.data(forKey: "notification_history"),
           let decoded = try? JSONDecoder().decode([NotificationData].self, from: data) {
            notificationHistory = decoded
            lastNotification = decoded.first
        }
    }
    
    private func saveLastProcessedId() {
        UserDefaults.standard.set(lastProcessedId, forKey: "last_processed_notification_id")
    }
    
    private func loadLastProcessedId() {
        lastProcessedId = UserDefaults.standard.integer(forKey: "last_processed_notification_id")
    }
    
    func clearNotificationHistory() {
        notificationHistory.removeAll()
        lastNotification = nil
        saveNotificationHistory()
    }
    
    // MARK: - Debug Methods
    
    func getPollingStatus() -> String {
        return isPolling ? "Polling active (every 2s)" : "Polling inactive"
    }
    
    func getLastProcessedId() -> Int {
        return lastProcessedId
    }
}
