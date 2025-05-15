//
//  SentimentCore.swift
//  MoodGpt
//
//  Created by Test on 4/28/25.
//

import SwiftUI
import CoreLocation

// Create a namespace for all models and functions
enum Sentiment {
    // MARK: - API Models
    struct ApiResponse: Decodable {
        let data: String
    }
    
    // MARK: - Data Models
  
    
    struct CityEmotion: Identifiable {
        let id = UUID()
        let cityName: String
        let coordinate: CLLocationCoordinate2D
        let emoji: String
        let sentiment: String
        
        var intensity: Double = 0.7
        var thoughts: [String] = []
        var categories: [String] = []
    }
    
    // MARK: - Helper Functions
    static func getEmoji(_ s: String) -> String {
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
    
    static func getLabel(_ s: String) -> String {
        s.lowercased() == "neutral" ? "Neutral" : s.capitalized
    }
    
    static func getIntensity(_ s: String) -> Double {
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
    
    static func getColor(_ s: String) -> Color {
        switch s.lowercased() {
        case "happy", "joyful", "positive", "very positive": return .green
        case "sad", "negative", "very negative":             return .blue
        case "angry":                                        return .red
        case "fear":                                         return .purple
        case "excited":                                      return .orange
        case "calm":                                         return .mint
        case "tired":                                        return .gray
        case "surprised":                                    return .yellow
        case "confident":                                    return .indigo
        case "neutral", "mixed":                             return .gray
        default:                                             return .gray
        }
    }
}

// Add this extension for the Optional isNil property
extension Optional {
    var isNil: Bool {
        return self == nil
    }
}
