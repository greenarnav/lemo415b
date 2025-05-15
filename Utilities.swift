import SwiftUI

// MARK: - Sentiment Utilities Namespace
enum SentimentUtils {
    // Function to get emoji for sentiment
    static func getSentimentEmoji(sentiment: String) -> String {
        switch sentiment.lowercased() {
        case "happy", "joyful", "positive", "very positive":
            return "😊"
        case "sad", "negative", "very negative":
            return "😢"
        case "angry":
            return "😡"
        case "fear":
            return "😱"
        case "excited":
            return "😃"
        case "calm":
            return "😌"
        case "tired":
            return "😴"
        case "surprised":
            return "😲"
        case "confident":
            return "😎"
        case "neutral", "mixed":
            return "😐"
        default:
            return "🤔"
        }
    }
    
    // Overloaded function for direct string input
    static func getSentimentEmoji(_ sentiment: String) -> String {
        return getSentimentEmoji(sentiment: sentiment)
    }
    
    // Function to get label for sentiment
    static func getSentimentLabel(sentiment: String) -> String {
        return sentiment.lowercased() == "neutral" ? "Neutral" : sentiment.capitalized
    }
    
    // Function to get intensity for sentiment
    static func getSentimentIntensity(sentiment: String) -> Double {
        switch sentiment.lowercased() {
        case "very positive", "very happy":
            return 1.0
        case "positive", "happy", "joyful":
            return 0.8
        case "excited", "confident":
            return 0.7
        case "calm":
            return 0.6
        case "neutral", "mixed":
            return 0.5
        case "tired":
            return 0.4
        case "sad":
            return 0.3
        case "negative", "fear":
            return 0.2
        case "angry", "very negative":
            return 0.1
        default:
            return 0.5
        }
    }
    
    // Function to get color for sentiment
    static func getSentimentColor(sentiment: String) -> Color {
        switch sentiment.lowercased() {
        case "happy", "joyful", "positive", "very positive":
            return .green
        case "sad", "negative", "very negative":
            return .blue
        case "angry":
            return .red
        case "fear":
            return .purple
        case "excited":
            return .orange
        case "calm":
            return .mint
        case "tired":
            return .gray
        case "surprised":
            return .yellow
        case "confident":
            return .indigo
        case "neutral", "mixed":
            return .gray
        default:
            return .gray
        }
    }
}
