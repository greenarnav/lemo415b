//
//  for.swift
//  MoodGpt
//
//  Created by Test on 5/8/25.
//


import Foundation
import UserNotifications

// Extension for notification-related functionality
extension CitySentiment {
    
    // Generate a notification message based on sentiment
    func notificationMessage() -> String {
        let intensity = self.intensity
        
        // Base message based on sentiment label
        var message = "The mood in \(city) is \(label)"
        
        // Enhance message based on intensity
        if intensity > 0.8 {
            switch label.lowercased() {
            case "happy", "joyful", "positive", "very positive":
                message += " - people are feeling extremely upbeat!"
            case "excited":
                message += " - there's a lot of excitement in the air!"
            case "calm":
                message += " - there's a deeply peaceful atmosphere."
            case "confident":
                message += " - there's a strong sense of confidence here."
            default:
                message += " - it's particularly intense right now."
            }
        } else if intensity < 0.3 {
            switch label.lowercased() {
            case "sad", "negative", "very negative":
                message += " - but it's not too intense."
            case "angry":
                message += " - but tensions aren't too high."
            case "fear":
                message += " - but anxiety levels are manageable."
            default:
                message += " - at relatively low intensity."
            }
        }
        
        // Add thinking information if available
        if let firstThought = whatPeopleThinking.first, !firstThought.isEmpty {
            message += " People are thinking about: \"\(firstThought)\""
        }
        
        return message
    }
    
    // Generate a short notification title
    func notificationTitle() -> String {
        return "\(emoji) \(city) Mood: \(label)"
    }
}

// Separate class for handling city mood notifications
class CityMoodNotifier {
    // Shared instance
    static let shared = CityMoodNotifier()
    
    // Schedule notification for a city sentiment
    func scheduleNotification(for citySentiment: CitySentiment) {
        let notificationManager = NotificationManager.shared
        
        // Only proceed if notifications are authorized
        guard notificationManager.isAuthorized else { return }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = citySentiment.notificationTitle()
        content.body = citySentiment.notificationMessage()
        content.sound = .default
        
        // Create trigger (random time between 1-3 hours)
        let timeInterval = Double.random(in: 3600...10800) // 1-3 hours
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        // Create request
        let requestID = "city-mood-\(citySentiment.city.lowercased().replacingOccurrences(of: " ", with: "-"))-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling city mood notification: \(error.localizedDescription)")
            } else {
                print("Scheduled mood notification for \(citySentiment.city)")
            }
        }
    }
    
    // Schedule test notification for a city (immediate)
    func scheduleTestNotification(for citySentiment: CitySentiment, delay: TimeInterval = 5) {
        let notificationManager = NotificationManager.shared
        
        // Only proceed if notifications are authorized
        guard notificationManager.isAuthorized else { return }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Test: \(citySentiment.notificationTitle())"
        content.body = citySentiment.notificationMessage()
        content.sound = .default
        
        // Create trigger with short delay
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        // Create request
        let requestID = "test-city-mood-\(citySentiment.city.lowercased().replacingOccurrences(of: " ", with: "-"))-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling test notification: \(error.localizedDescription)")
            } else {
                print("Scheduled test notification for \(citySentiment.city)")
            }
        }
    }
    
    // Schedule notifications for multiple cities
    func scheduleMultipleCityNotifications(cities: [CitySentiment], maxCount: Int = 3) {
        // Only proceed if notifications are authorized
        guard NotificationManager.shared.isAuthorized else { return }
        
        // Pick random cities to notify about (up to maxCount)
        let citiesToNotify = cities.shuffled().prefix(min(maxCount, cities.count))
        
        // Schedule notifications with increasing delays
        var delay: TimeInterval = 3600 // Start with 1 hour
        
        for city in citiesToNotify {
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = city.notificationTitle()
            content.body = city.notificationMessage()
            content.sound = .default
            
            // Create trigger
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            
            // Create request
            let requestID = "multi-city-\(city.city.lowercased().replacingOccurrences(of: " ", with: "-"))-\(UUID().uuidString)"
            let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
            
            // Schedule notification
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling city notification: \(error.localizedDescription)")
                } else {
                    print("Scheduled notification for \(city.city) in \(Int(delay/60)) minutes")
                }
            }
            
            // Increase delay for next notification (add 30-90 minutes)
            delay += Double.random(in: 1800...5400)
        }
    }
}