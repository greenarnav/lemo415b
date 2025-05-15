//
//  integrates.swift
//  MoodGpt
//
//  Created by Test on 5/8/25.
//


import SwiftUI
import UserNotifications

// This class integrates all notification functionality into one place
// to ensure easy access and maintenance
class NotificationIntegration {
    // Singleton access
    static let shared = NotificationIntegration()
    
    // Reference to notification manager
    private let notificationManager = NotificationManager.shared
    
    // Keep track of whether we've already set up initial notifications
    private var initialNotificationsScheduled = false
    
    // MARK: - Setup Methods
    
    // Initialize notification system
    func setup() {
        // Request permission if not already granted
        if !notificationManager.isAuthorized {
            notificationManager.requestPermission()
        }
        
        // Update pending notifications list
        notificationManager.updatePendingNotifications()
    }
    
    // MARK: - Application Lifecycle Methods
    
    // Handle when application becomes active
    func applicationDidBecomeActive() {
        // Reset badge count
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // Update pending notifications
        notificationManager.updatePendingNotifications()
    }
    
    // Handle when application enters background
    func applicationDidEnterBackground() {
        // Make sure we have at least a few notifications scheduled
        ensureNotificationsScheduled()
    }
    
    // MARK: - Notification Scheduling
    
    // Schedule test notifications (10 notifications, 30 seconds apart)
    func scheduleTestNotifications() {
        notificationManager.scheduleTestNotifications()
    }
    
    // Schedule mood check notification
    func scheduleMoodCheckNotification(delayInHours: Double = 12) {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "How are you feeling?"
        content.body = "Take a moment to check in with your mood and record it in MoodGpt."
        content.sound = .default
        
        // Create trigger (convert hours to seconds)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delayInHours * 3600, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(identifier: "mood-check-\(UUID().uuidString)", content: content, trigger: trigger)
        
        // Add request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling mood check: \(error.localizedDescription)")
            }
        }
    }
    
    // Schedule notifications for multiple cities
    func scheduleCityNotifications(cities: [CitySentiment], maxCount: Int = 3) {
        // Use the CityMoodNotifier instead
        CityMoodNotifier.shared.scheduleMultipleCityNotifications(cities: cities, maxCount: maxCount)
    }
    
    // Ensure we have at least some notifications scheduled
    func ensureNotificationsScheduled() {
        // Only proceed if notifications are authorized
        guard notificationManager.isAuthorized else { return }
        
        // Check if we need to schedule initial notifications
        if !initialNotificationsScheduled {
            // Schedule mood check for tomorrow
            scheduleMoodCheckNotification(delayInHours: 24)
            
            // Mark as done
            initialNotificationsScheduled = true
        }
        
        // Check how many notifications are pending
        notificationManager.updatePendingNotifications()
        
        // If we have fewer than 3 notifications, schedule a mood check
        if notificationManager.pendingNotifications.count < 3 {
            // Schedule a random mood check
            let randomHours = Double.random(in: 6...36)
            scheduleMoodCheckNotification(delayInHours: randomHours)
        }
    }
    
    // Cancel all notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        notificationManager.updatePendingNotifications()
    }
}