//
//  SentimentHelper.swift
//  MoodGpt
//
//  Created by Test on 5/7/25.
//

import Foundation
import CoreLocation

// MARK: - SentimentHelper

struct SentimentHelper {
    static func getEmoji(for sentiment: String) -> String {
        let normalizedSentiment = sentiment.lowercased()
        
        switch normalizedSentiment {
        case "happy", "positive", "joy":
            return "😀"
        case "sad", "negative":
            return "😢"
        case "angry", "frustrated":
            return "😡"
        case "surprised", "shocked":
            return "😮"
        case "love", "loved":
            return "😍"
        case "bored":
            return "🥱"
        case "scared", "fearful", "nervous", "anxious":
            return "😱"
        case "thoughtful", "reflective":
            return "🤔"
        case "calm", "peaceful", "relaxed":
            return "😌"
        case "excited", "enthusiastic":
            return "🤩"
        case "cool", "confident":
            return "😎"
        case "mixed", "complex":
            return "🙃"
        case "sleepy", "tired":
            return "😴"
        case "disgusted":
            return "🤮"
        default:
            return "😐"
        }
    }
    
    static func getRandomSentiment() -> String {
        let sentiments = [
            "happy", "sad", "angry", "surprised", "love", "bored",
            "scared", "thoughtful", "calm", "excited", "cool",
            "mixed", "sleepy", "disgusted", "positive", "negative"
        ]
        return sentiments.randomElement() ?? "neutral"
    }
}
