//
//  APISummary.swift
//  MoodGpt
//
//  Created by Test on 5/14/25.
//

//
//  APISummary.swift
//  MoodGpt
//
//  Provides summary of API endpoints used throughout the app
//

import Foundation

/**
 # API Endpoints Reference
 
 This file documents all API endpoints used throughout the MoodGpt app.
 Each endpoint includes details about its purpose, parameters, and response format.
 
 ## Main API Endpoints
 
 ### 1. Activity Tracking API
 
 Base URL: https://activity-opal.vercel.app/
 
 #### - POST /log-activity
 
 Logs user activity for tracking and analytics purposes.
 
 - Method: POST
 - Content-Type: application/json
 - Request Body:
 ```json
 {
   "email": "user@example.com",
   "activity": {
     "action": "opened",
     "device": "mobile",
     "location": "NY",
     // Additional activity properties
   }
 }
 ```
 - Response: HTTP 200 OK with confirmation message
 
 ### 2. City Sentiment API
 
 Base URL: https://mainoverallapi.vercel.app
 
 #### - GET /
 
 Retrieves sentiment data for various cities.
 
 - Method: GET
 - Response: JSON object containing city sentiment data
 ```json
 {
   "data": "{\"New York\":{\"what_is_their_sentiment\":\"happy\",\"what_are_people_thinking\":[\"thoughts\"],\"what_do_people_care\":[\"topics\"]}}"
 }
 ```
 
 ### 3. Location Tracking API
 
 Base URL: https://location-tracking-zeta.vercel.app
 
 #### - POST /track
 
 Tracks user location data.
 
 - Method: POST
 - Content-Type: application/json
 - Request Body:
 ```json
 {
   "username": "user_123",
   "latitude": 40.7128,
   "longitude": -74.0060
 }
 ```
 
 #### - GET /track/{username}
 
 Retrieves location history for a user.
 
 - Method: GET
 - Path Parameter: username
 - Response: Array of location log items
 
 ### 4. Contacts API
 
 Base URL: https://contactsapi.vercel.app
 
 #### - POST /add_contact
 
 Adds or updates user contacts.
 
 - Method: POST
 - Content-Type: application/json
 - Request Body:
 ```json
 {
   "username": "user_123",
   "contacts": [
     {
       "name": "John Doe",
       "phone": "+1234567890"
     }
   ]
 }
 ```
 
 #### - GET /search/{username}
 
 Retrieves contacts for a username.
 
 - Method: GET
 - Path Parameter: username
 - Response: Contacts list for the specified user
 
 ### 5. Notifications API
 
 Base URL: https://notification-inky.vercel.app/
 
 #### - GET /notifications
 
 Fetches pending notifications for users.
 
 - Method: GET
 - Response: Array of notification objects
 
 ## API Refresh Intervals
 
 - Map Data: Every 5 minutes (formerly 30 minutes)
 - Location Data: Every 5 minutes (formerly 30 minutes)
 - Notifications: Every 2 seconds (polling)
 - Usage Statistics: Every 5 minutes
 
 ## Authentication
 
 Most endpoints use a simple username-based authentication rather than OAuth.
 The username is stored in UserDefaults with the key "moodgpt_username".
 
 ## Error Handling
 
 All API requests should include proper error handling and reporting.
 Errors are tracked with EnhancedTrackingService and reported to the tracking API.
 
 **/

// This enum is just to provide a structured reference to all API endpoints
enum APIEndpoints {
    // Activity tracking
    static let activityLog = "https://activity-opal.vercel.app/log-activity"
    
    // City sentiment
    static let citySentiment = "https://mainoverallapi.vercel.app"
    
    // Location tracking
    static let locationTrack = "https://location-tracking-zeta.vercel.app/track"
    static let locationHistory = "https://location-tracking-zeta.vercel.app/track/" // + username
    
    // Contacts
    static let contactsAdd = "https://contactsapi.vercel.app/add_contact"
    static let contactsSearch = "https://contactsapi.vercel.app/search/" // + username
    
    // Notifications
    static let notifications = "https://notification-inky.vercel.app/notifications"
    
    // Refresh intervals (in seconds)
    enum RefreshIntervals {
        static let map = 300        // 5 minutes
        static let location = 300   // 5 minutes
        static let notification = 2 // 2 seconds
        static let statistics = 300 // 5 minutes
    }
}

// Example of how to use this reference
struct APIReferenceExample {
    func logActivity() {
        print("Logging activity to: \(APIEndpoints.activityLog)")
    }
    
    func refreshMap() {
        print("Map should refresh every \(APIEndpoints.RefreshIntervals.map) seconds")
    }
}
