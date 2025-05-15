import Foundation

// SentimentHelper extension - add functionality without redefining the existing type
extension SentimentHelper {
    // This will only be added if not already defined in your SentimentHelper
    static func getRandomSentiment() -> String {
        let sentiments = [
            "happy", "sad", "angry", "surprised", "love", "bored",
            "scared", "thoughtful", "calm", "excited", "cool",
            "mixed", "sleepy", "disgusted", "positive", "negative"
        ]
        
        return sentiments.randomElement() ?? "neutral"
    }
}
