//
//  DataModels.swift
//  MoodGpt
//
//  All data models used throughout the app
//

import Foundation
import CoreLocation

// MARK: - User Profile
struct UserProfile: Codable {
    let userId: String
    let email: String
    let name: String
    let joinedAt: Date
    var preferences: [RecommendationCategory: Double]
    var favoriteCategories: [RecommendationCategory]
    var location: String?
    
    init(userId: String, email: String = "", name: String = "") {
        self.userId = userId
        self.email = email
        self.name = name
        self.joinedAt = Date()
        self.preferences = RecommendationCategory.defaultPreferences()
        self.favoriteCategories = []
        self.location = nil
    }
}

// MARK: - Recommendation Models
struct RecommendableItem: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: RecommendationCategory
    let relevanceScore: Double
    let imageUrl: String?
    let metadata: [String: String]
    let timestamp: Date
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String,
         category: RecommendationCategory,
         relevanceScore: Double,
         imageUrl: String? = nil,
         metadata: [String: String] = [:]) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.relevanceScore = relevanceScore
        self.imageUrl = imageUrl
        self.metadata = metadata
        self.timestamp = Date()
    }
}

enum RecommendationCategory: String, CaseIterable, Codable {
    case weather = "Weather"
    case animals = "Animals"
    case food = "Food"
    case news = "News"
    case sports = "Sports"
    case entertainment = "Entertainment"
    case technology = "Technology"
    case health = "Health"
    case travel = "Travel"
    case business = "Business"
    
    static func defaultPreferences() -> [RecommendationCategory: Double] {
        return [
            .weather: 0.2,
            .animals: 0.15,
            .food: 0.15,
            .news: 0.25,
            .sports: 0.25
        ]
    }
}

// MARK: - User Notification Models
struct UserNotification: Codable {
    let userId: String
    let type: NotificationType
    let title: String
    let body: String
    let data: [String: String]?
    let scheduledAt: Date?
    let imageUrl: String?
    let category: String?
    let threadId: String?
    let actionButtons: [NotificationAction]?
    
    init(userId: String,
         type: NotificationType,
         title: String,
         body: String,
         data: [String: String]? = nil,
         scheduledAt: Date? = nil,
         imageUrl: String? = nil,
         category: String? = nil,
         threadId: String? = nil,
         actionButtons: [NotificationAction]? = nil) {
        self.userId = userId
        self.type = type
        self.title = title
        self.body = body
        self.data = data
        self.scheduledAt = scheduledAt
        self.imageUrl = imageUrl
        self.category = category
        self.threadId = threadId
        self.actionButtons = actionButtons
    }
}

enum NotificationType: String, Codable {
    case moodCheck = "mood_check"
    case cityAlert = "city_alert"
    case recommendation = "recommendation"
    case social = "social"
    case system = "system"
    case reminder = "reminder"
}

struct NotificationAction: Codable {
    let identifier: String
    let title: String
    let options: Set<NotificationActionOption>
    let textInputPlaceholder: String?
    
    enum NotificationActionOption: String, Codable {
        case foreground
        case destructive
        case authenticationRequired
    }
}

// MARK: - API Response Wrapper
struct APIResponseWrapper<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: APIErrorResponse?
    let metadata: APIMetadata?
}

struct APIErrorResponse: Codable {
    let code: String
    let message: String
    let details: [String: String]?
}

struct APIMetadata: Codable {
    let requestId: String
    let timestamp: Date
    let version: String
    let cached: Bool
}

// MARK: - Location Models
// Remove the duplicate declaration - this should only be in ApiIntegrationService
// struct LocationLogItem: Codable {
//     let latitude: Double
//     let longitude: Double
//     let timestamp: String
//     let username: String
//     let accuracy: Double?
//     let altitude: Double?
//     let speed: Double?
// }

// MARK: - Contact Models
struct ContactUploadData: Codable {  // Renamed from ContactUpload
    let username: String
    let contacts: [ContactData]      // Updated to use renamed type
}

struct ContactData: Codable {        // Renamed from ContactItem
    let name: String
    let phone: String
    let email: String?
    let location: String?
}

// MARK: - Empty Response for void API calls
struct EmptyResponse: Codable {}

// MARK: - Device Information
struct DeviceInfo: Codable {
    let deviceId: String
    let model: String
    let osVersion: String
    let appVersion: String
    let screenSize: CGSize
    let batteryLevel: Float
    let isJailbroken: Bool
    let hasNotch: Bool
    let timezone: String
    let locale: String
}
