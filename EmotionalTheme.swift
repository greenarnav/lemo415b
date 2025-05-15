//
//  EmotionalTheme.swift
//  MoodGpt
//
//  Updated color scheme - pink for positive, yellow for other moods
//

import SwiftUI

struct EmotionTheme {
    // Primary gradient colors for each emotion - updated color scheme
    static func gradientColors(for emotion: String) -> [Color] {
        switch emotion.lowercased() {
        case "happy", "joyful", "positive", "very positive":
            // Pink gradient for positive instead of yellow
            return [Color.pink.opacity(0.7), Color.purple.opacity(0.4), Color.pink.opacity(0.3)]
            
        case "sad", "negative", "very negative":
            // Cool, blue gradient
            return [Color.blue.opacity(0.7), Color.indigo.opacity(0.6), Color.blue.opacity(0.3)]
            
        case "angry":
            // Intense red gradient
            return [Color.red.opacity(0.7), Color.pink.opacity(0.6), Color.red.opacity(0.3)]
            
        case "fear":
            // Deep purple gradient
            return [Color.purple.opacity(0.7), Color.indigo.opacity(0.6), Color.purple.opacity(0.3)]
            
        case "excited":
            // Now using yellow for excited (moved from positive)
            return [Color.yellow.opacity(0.7), Color.orange.opacity(0.6), Color.yellow.opacity(0.3)]
            
        case "calm":
            // Serene teal/mint gradient
            return [Color.mint.opacity(0.7), Color.teal.opacity(0.5), Color.mint.opacity(0.3)]
            
        case "tired":
            // Muted, soft gradient
            return [Color.gray.opacity(0.7), Color.blue.opacity(0.3), Color.gray.opacity(0.2)]
            
        case "surprised":
            // Bright, contrasting gradient
            return [Color.orange.opacity(0.7), Color.yellow.opacity(0.5), Color.orange.opacity(0.3)]
            
        case "confident":
            // Rich, deep gradient
            return [Color.indigo.opacity(0.7), Color.purple.opacity(0.5), Color.blue.opacity(0.3)]
            
        case "neutral", "mixed":
            // Balanced, neutral gradient
            return [Color.gray.opacity(0.5), Color.blue.opacity(0.3), Color.white.opacity(0.3)]
            
        default:
            // Default gradient
            return [Color.blue.opacity(0.6), Color.purple.opacity(0.5), Color.white.opacity(0.3)]
        }
    }
    
    // Card background color based on emotion - updated to match new gradients
    static func cardColor(for emotion: String) -> Color {
        switch emotion.lowercased() {
        case "happy", "joyful", "positive", "very positive":
            return Color.pink.opacity(0.2)
        case "sad", "negative", "very negative":
            return Color.blue.opacity(0.2)
        case "angry":
            return Color.red.opacity(0.2)
        case "fear":
            return Color.purple.opacity(0.2)
        case "excited":
            return Color.yellow.opacity(0.2)
        case "calm":
            return Color.mint.opacity(0.2)
        case "tired":
            return Color.gray.opacity(0.2)
        case "surprised":
            return Color.orange.opacity(0.2)
        case "confident":
            return Color.indigo.opacity(0.2)
        case "neutral", "mixed":
            return Color.gray.opacity(0.2)
        default:
            return Color.gray.opacity(0.2)
        }
    }
    
    // Text color for each emotion to ensure readability
    // Updated to ensure good contrast with new background colors
    static func textColor(for emotion: String) -> Color {
        switch emotion.lowercased() {
        case "happy", "joyful", "positive", "very positive":
            return Color.white // White text on pink background
        case "excited", "surprised":
            return Color.black.opacity(0.8) // Dark text on light backgrounds
        default:
            return Color.white // White text for other emotions
        }
    }
}
