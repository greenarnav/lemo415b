import SwiftUI
import Contacts
import CoreLocation

// MARK: - Local SentimentService Implementation
fileprivate struct LocalSentimentService {
    static func fetch(city: String) async throws -> String {
        // This is a placeholder for your actual API call
        // You would replace this with your real implementation
        // For demo, return random sentiments
        let sentiments = ["happy", "sad", "excited", "calm", "neutral"]
        return sentiments.randomElement() ?? "neutral"
    }
}

@MainActor
final class ContactRowViewModel: ObservableObject, Identifiable {
    let id = UUID()
    let name: String
    let phone: String
    @Published var city = "—"
    @Published var emoji = "❓"
    
    init(contact: CNContact) {
        name = CNContactFormatter.string(from: contact, style: .fullName) ?? "No name"
        phone = contact.phoneNumbers.first?.value.stringValue ?? ""
        Task { await resolve() }
    }
    
    private func resolve() async {
        // naïve area-code extraction ("+1 (602) 555-…" -> 602)
        if let range = phone.range(of: #"\d{3}"#, options: .regularExpression), !range.isEmpty {
            let area = String(phone[range])
            
            if let (cityName, _) = LocationLookup.shared.city(for: area) {
                self.city = cityName
                // try API
                do {
                    let sentiment = try await LocalSentimentService.fetch(city: cityName)
                    self.emoji = getEmoji(for: sentiment)
                } catch {
                    print("Error fetching sentiment: \(error)")
                }
            }
        }
    }
    
    // Local helper function to get emoji for sentiment
    private func getEmoji(for sentiment: String) -> String {
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
}
