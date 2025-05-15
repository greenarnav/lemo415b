//
//  CitySentiment.swift
//  MoodGpt
//
//  Created by Test on 4/30/25.
//  Last revised 2025‑05‑08
//

import SwiftUI
import CoreLocation

// MARK: - Primary Data Model
public struct CitySentiment: Identifiable, Hashable {
    public let id = UUID()
    public let city: String
    public let emoji: String
    public let label: String
    public let intensity: Double
    public var whatPeopleThinking: [String]
    public var whatPeopleCare:   [String]

    public init(
        city: String,
        emoji: String,
        label: String,
        intensity: Double,
        whatPeopleThinking: [String] = [],
        whatPeopleCare: [String] = []
    ) {
        self.city               = city
        self.emoji              = emoji
        self.label              = label
        self.intensity          = intensity
        self.whatPeopleThinking = whatPeopleThinking
        self.whatPeopleCare     = whatPeopleCare
    }

    public static func == (lhs: CitySentiment, rhs: CitySentiment) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Map‑Pin Emotion Model
public struct CitySentimentEmotion: Identifiable {
    public let id = UUID()
    public let cityName:  String
    public let coordinate: CLLocationCoordinate2D
    public let emoji:     String
    public let sentiment: String
}

// MARK: - Lightweight API DTO
public struct CitySentimentResponse: Decodable {
    public let data: String
}

// MARK: - Area‑Code Lookup Helper
public enum CitySentimentAreaCodeLookup {
    public static func city(for areaCode: String) -> (city: String, state: String)? {
        [
            "602": ("Phoenix", "AZ"),
            "480": ("Tempe",   "AZ"),
            "212": ("New York","NY")
        ][areaCode]
    }
}

// MARK: - Sentiment Utilities  (renamed!)
public enum CitySentimentHelper {

    // Emoji picker
    public static func emoji(for sentiment: String) -> String {
        switch sentiment.lowercased() {
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

    // User‑facing label
    public static func label(for sentiment: String) -> String {
        sentiment.lowercased() == "neutral" ? "Neutral" : sentiment.capitalized
    }

    // 0‑1 intensity gauge
    public static func intensity(for sentiment: String) -> Double {
        switch sentiment.lowercased() {
        case "very positive", "very happy":   return 1.0
        case "positive", "happy", "joyful":   return 0.8
        case "excited", "confident":          return 0.7
        case "calm":                          return 0.6
        case "neutral", "mixed":              return 0.5
        case "tired":                         return 0.4
        case "sad":                           return 0.3
        case "negative", "fear":              return 0.2
        case "angry", "very negative":        return 0.1
        default:                              return 0.5
        }
    }

    // Color coding for UI
    public static func color(for sentiment: String) -> Color {
        switch sentiment.lowercased() {
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
