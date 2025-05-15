//
//  NotificationManager.swift
//  MoodGpt
//
//  Created by Test on 5/8/25.
//


import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    // Singleton instance
    static let shared = NotificationManager()
    
    // Published properties
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    // Test notification counter
    private var testNotificationCount = 0
    private let maxTestNotifications = 10
    
    // Initialize
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }
    
    // Check current notification authorization status
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // Request notification permissions
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                
                if granted {
                    print("Notification permission granted")
                } else if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Schedule a test notification series (10 notifications, 30 seconds apart)
    func scheduleTestNotifications() {
        // Reset counter
        testNotificationCount = 0
        
        // Cancel any existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule the first notification
        scheduleNextTestNotification()
    }
    
    // Schedule a single test notification
    private func scheduleNextTestNotification() {
        guard testNotificationCount < maxTestNotifications else { return }
        
        testNotificationCount += 1
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "MoodGpt Notification"
        content.body = "Test notification #\(testNotificationCount) of \(maxTestNotifications)"
        content.sound = .default
        
        // Create trigger (30 seconds from now)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30, repeats: false)
        
        // Create request with unique identifier
        let requestIdentifier = "moodgpt-test-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
        
        // Add request to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Scheduled test notification #\(self.testNotificationCount)")
                
                // Schedule the next notification if not at max
                if self.testNotificationCount < self.maxTestNotifications {
                    // Wait a moment to ensure notifications are properly queued
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.scheduleNextTestNotification()
                    }
                }
            }
        }
        
        // Update pending notifications list
        updatePendingNotifications()
    }
    
    // Schedule a mood check notification
    func scheduleMoodCheckNotification(after timeInterval: TimeInterval = 3600) {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "How are you feeling?"
        content.body = "Take a moment to check in with your mood."
        content.sound = .default
        
        // Create trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        // Create request with unique identifier
        let requestIdentifier = "moodgpt-check-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
        
        // Add request to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling mood check: \(error.localizedDescription)")
            } else {
                print("Scheduled mood check notification")
            }
        }
        
        // Update pending notifications list
        updatePendingNotifications()
    }
    
    // Schedule a notification for a city's mood change
    func scheduleCityMoodNotification(city: String, mood: String, after timeInterval: TimeInterval = 7200) {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Mood Alert: \(city)"
        content.body = "The mood in \(city) has changed to \(mood)."
        content.sound = .default
        
        // Create trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        // Create request with unique identifier
        let requestIdentifier = "moodgpt-city-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
        
        // Add request to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling city mood notification: \(error.localizedDescription)")
            } else {
                print("Scheduled city mood notification for \(city)")
            }
        }
        
        // Update pending notifications list
        updatePendingNotifications()
    }
    
    // Cancel all pending notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        updatePendingNotifications()
    }
    
    // Update the list of pending notifications
    func updatePendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.pendingNotifications = requests
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate Methods
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    // Handle notification response when user taps on a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        print("User tapped on notification: \(identifier)")
        
        // You could add custom logic here based on the notification identifier
        
        completionHandler()
    }
}