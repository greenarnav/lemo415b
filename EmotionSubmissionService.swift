//
//  EmotionSubmissionService.swift
//  MoodGpt
//

import Foundation
import SwiftUI

final class EmotionSubmissionService: ObservableObject {
    static let shared = EmotionSubmissionService()
    
    @Published var isSubmitting = false
    @Published var lastSubmissionTime: Date?
    @Published var error: String?
    
    private let apiEndpoint = "https://your-vercel-app.vercel.app/api/submit-emotion"
    
    struct EmotionSubmission: Codable {
        let username: String
        let emotion: String
        let location: String
        let timestamp: String
        let latitude: Double?
        let longitude: Double?
    }
    
    private init() {}
    
    func submitEmotion(emotion: String, location: String, latitude: Double? = nil, longitude: Double? = nil) async {
        await MainActor.run {
            self.isSubmitting = true
            self.error = nil
        }
        
        let username = UserDefaults.standard.string(forKey: "moodgpt_username") ?? "anonymous_\(UUID().uuidString.prefix(8))"
        
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: Date())
        
        let submission = EmotionSubmission(
            username: username,
            emotion: emotion,
            location: location,
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude
        )
        
        do {
            guard let url = URL(string: apiEndpoint) else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(submission)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                await MainActor.run {
                    self.lastSubmissionTime = Date()
                    print("Emotion submitted successfully: \(emotion)")
                }
            } else {
                throw URLError(.badServerResponse)
            }
            
        } catch {
            await MainActor.run {
                self.error = "Failed to submit emotion: \(error.localizedDescription)"
                print("Emotion submission error: \(error)")
            }
        }
        
        await MainActor.run {
            self.isSubmitting = false
        }
    }
    
    func canSubmitEmotion() -> Bool {
        guard let lastTime = lastSubmissionTime else { return true }
        return Date().timeIntervalSince(lastTime) > 30
    }
}
