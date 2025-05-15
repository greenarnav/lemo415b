//
//  SentimentModel.swift
//  MoodGpt
//
//  Created by Test on 4/28/25.
//
//  SentimentModels.swift
import SwiftUI
import CoreLocation

// ---------- API shell ----------
struct ApiResponse: Decodable {            // <- ONE canonical copy
    let data: String
}

// ---------- Core app models ----------


struct CityEmotion: Identifiable {
    let id        = UUID()
    let cityName  : String
    let coordinate: CLLocationCoordinate2D
    let emoji     : String
    let sentiment : String
}

// ---------- Global helpers ----------
@inline(__always) func getSentimentEmoji(_ s: String) -> String {
    switch s.lowercased() {
    case "happy", "joyful", "positive", "very positive": return "😊"
    case "sad", "negative", "very negative"            : return "😢"
    case "angry"                                       : return "😡"
    case "fear"                                        : return "😱"
    case "excited"                                     : return "😃"
    case "calm"                                        : return "😌"
    case "tired"                                       : return "😴"
    case "surprised"                                   : return "😲"
    case "confident"                                   : return "😎"
    case "neutral", "mixed"                            : return "😐"
    default                                            : return "🤔"
    }
}

@inline(__always) func getSentimentLabel(_ s: String) -> String {
    s.lowercased() == "neutral" ? "Neutral" : s.capitalized
}

@inline(__always) func getSentimentIntensity(_ s: String) -> Double {
    switch s.lowercased() {
    case "very positive", "very happy"  : return 1.0
    case "positive", "happy", "joyful"  : return 0.8
    case "excited", "confident"         : return 0.7
    case "calm"                         : return 0.6
    case "neutral", "mixed"             : return 0.5
    case "tired"                        : return 0.4
    case "sad"                          : return 0.3
    case "negative", "fear"             : return 0.2
    case "angry", "very negative"       : return 0.1
    default                             : return 0.5
    }
}

/// Convenience colour
@inline(__always) func getSentimentColor(_ s: String) -> Color {
    switch s.lowercased() {
    case "happy", "joyful", "positive", "very positive": return .green
    case "sad", "negative", "very negative"            : return .blue
    case "angry"                                       : return .red
    case "fear"                                        : return .purple
    case "excited"                                     : return .orange
    case "calm"                                        : return .mint
    case "tired"                                       : return .gray
    case "surprised"                                   : return .yellow
    case "confident"                                   : return .indigo
    case "neutral", "mixed"                            : return .gray
    default                                            : return .gray
    }
}

