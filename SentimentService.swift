//
//  SentimentService.swift
//  MoodGpt
//
//  Created by Test on 4/28/25.
//

import Foundation
import SwiftUI

// Define any types you need directly in this file
// This avoids depending on the Sentiment namespace

// MARK: - Minimal ApiResponse for this file only
fileprivate struct LocalApiResponse: Decodable {
    let data: String
}

// MARK: - Minimal CitySentiment for this file only
fileprivate struct LocalCitySentiment {
    let city: String
    let emoji: String
    let label: String
    let intensity: Double
    let whatPeopleThinking: [String]
    let whatPeopleCare: [String]
}

// MARK: - SentimentService (actor-safe cache around the REST endpoint)
actor SentimentService {
    
    // -----------------------------------------------------------------
    //  Singleton access
    // -----------------------------------------------------------------
    static let shared = SentimentService()
    
    // -----------------------------------------------------------------
    //  Per-process in-memory cache   〈city name → LocalCitySentiment〉
    // -----------------------------------------------------------------
    private var cache: [String : LocalCitySentiment] = [:]
    
    // -----------------------------------------------------------------
    //  Helper functions (defined locally to avoid namespace issues)
    // -----------------------------------------------------------------
    private func getEmoji(_ s: String) -> String {
        switch s.lowercased() {
        case "happy", "joyful", "positive", "very positive": return "😊"
        case "sad", "negative", "very negative":             return "😢"
        case "angry":                                        return "😡"
        case "fear":                                         return "😱"
        case "excited":                                      return "😃"
        case "calm":                                         return "😌"
        case "tired":                                        return "😴"
        case "surprised":                                    return "😲"
        case "confident":                                    return "😎"
        case "neutral", "mixed":                             return "😐"
        default:                                             return "🤔"
        }
    }
    
    private func getLabel(_ s: String) -> String {
        s.lowercased() == "neutral" ? "Neutral" : s.capitalized
    }
    
    private func getIntensity(_ s: String) -> Double {
        switch s.lowercased() {
        case "very positive", "very happy":    return 1.0
        case "positive", "happy", "joyful":    return 0.8
        case "excited", "confident":           return 0.7
        case "calm":                           return 0.6
        case "neutral", "mixed":               return 0.5
        case "tired":                          return 0.4
        case "sad":                            return 0.3
        case "negative", "fear":               return 0.2
        case "angry", "very negative":         return 0.1
        default:                               return 0.5
        }
    }
    
    // -----------------------------------------------------------------
    //  Public API   (throws on network / decoding failure)
    // -----------------------------------------------------------------
    fileprivate func cityInfo(_ city: String) async throws -> LocalCitySentiment {
        
        // 1.  Fast path  – return cached value if we already fetched it
        if let hit = cache[city] { return hit }
        
        // 2.  Hit the backend
        let url = URL(string: "https://mainoverallapi.vercel.app")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let apiResponse = try JSONDecoder().decode(LocalApiResponse.self, from: data)
        
        // 3.  The server returns a *string* that itself is JSON; unwrap it
        guard
            let jsonData = apiResponse.data.data(using: .utf8),
            let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String:[String:Any]],
            let info = dict[city]
        else { throw URLError(.badServerResponse) }
        
        // 4.  Pull out the fields we care about
        let sentimentString = info["what_is_their_sentiment"] as? String ?? "neutral"
        let thinkList = info["what_are_people_thinking"] as? [String] ?? []
        let careList = info["what_do_people_care"] as? [String] ?? []
        
        // 5.  Build our model
        let model = LocalCitySentiment(
            city: city,
            emoji: getEmoji(sentimentString),
            label: getLabel(sentimentString),
            intensity: getIntensity(sentimentString),
            whatPeopleThinking: thinkList,
            whatPeopleCare: careList
        )
        
        // 6.  Cache & return
        cache[city] = model
        return model
    }
    
    // Convenience alias used by ContactRowViewModel
    static func fetch(city: String) async throws -> String {
        try await SentimentService.shared.cityInfo(city).label
    }
}
