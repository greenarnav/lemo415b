//
//  EmotionalDatabase.swift
//  MoodGpt
//
//  Created by Test on 4/26/25.
//

import Foundation
import SwiftUI

// MARK: - Emotion Database
class EmotionDatabase: ObservableObject {
    @Published var userEmotions: [UserEmotion] = []
    
    struct UserEmotion: Identifiable, Codable {
        let id: UUID
        let emotion: String
        let location: String
        let timestamp: Date
        
        init(id: UUID = UUID(), emotion: String, location: String, timestamp: Date) {
            self.id = id
            self.emotion = emotion
            self.location = location
            self.timestamp = timestamp
        }
    }
    
    init() {
        loadEmotions()
    }
    
    func saveEmotion(emotion: String, location: String, timestamp: Date) {
        let newEmotion = UserEmotion(emotion: emotion, location: location, timestamp: timestamp)
        userEmotions.append(newEmotion)
        saveEmotions()
        
        // Also send to remote database when credentials are provided
        sendToRemoteDatabase(newEmotion)
    }
    
    private func sendToRemoteDatabase(_ emotion: UserEmotion) {
        // This function will be implemented when database credentials are provided
        // For now, we'll just print to console
        print("Saving to remote database: \(emotion.emotion) at \(emotion.location)")
        
        // TODO: When credentials are provided, implement this:
        /*
        guard let url = URL(string: "https://your-database-url.com/emotions") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let emotionData = [
            "id": emotion.id.uuidString,
            "emotion": emotion.emotion,
            "location": emotion.location,
            "timestamp": ISO8601DateFormatter().string(from: emotion.timestamp)
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: emotionData)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error saving emotion to database: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("No HTTP response")
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    print("Emotion saved successfully to remote database")
                } else {
                    print("Error: HTTP \(httpResponse.statusCode)")
                }
            }.resume()
        } catch {
            print("Error serializing emotion data: \(error)")
        }
        */
    }
    
    // MARK: - Local Storage
    private func saveEmotions() {
        if let encoded = try? JSONEncoder().encode(userEmotions) {
            UserDefaults.standard.set(encoded, forKey: "userEmotions")
        }
    }
    
    private func loadEmotions() {
        if let savedEmotions = UserDefaults.standard.data(forKey: "userEmotions") {
            if let decodedEmotions = try? JSONDecoder().decode([UserEmotion].self, from: savedEmotions) {
                userEmotions = decodedEmotions
            }
        }
    }
}
