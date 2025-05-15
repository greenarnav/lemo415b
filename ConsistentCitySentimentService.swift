//
//  ConsistentCitySentimentService.swift
//  MoodGpt
//
//  Provides consistent city sentiment data
//

import Foundation
import SwiftUI

class ConsistentCitySentimentService: ObservableObject {
    static let shared = ConsistentCitySentimentService()
    
    @Published var citySentiments: [CitySentiment] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // Cache to ensure consistency
    private var cache = [String: CitySentiment]()
    private let cacheKey = "city_sentiments_cache"
    
    init() {
        loadCachedData()
    }
    
    // Fixed sentiment generation based on city name hash
    private func generateConsistentSentiment(for city: String) -> (emoji: String, label: String, intensity: Double) {
        // Use city name to generate consistent but varied sentiments
        let hash = abs(city.hashValue)
        
        let sentiments: [(emoji: String, label: String, intensity: Double)] = [
            ("😊", "Happy", 0.8),
            ("😌", "Calm", 0.7),
            ("😎", "Confident", 0.85),
            ("🤔", "Thoughtful", 0.6),
            ("😃", "Excited", 0.9),
            ("😐", "Neutral", 0.5),
            ("😇", "Joyful", 0.95),
            ("🙂", "Positive", 0.75)
        ]
        
        let index = hash % sentiments.count
        return sentiments[index]
    }
    
    // Generate consistent thoughts based on city and sentiment
    private func generateConsistentThoughts(for city: String, sentiment: String) -> [String] {
        // Use city name + sentiment to generate consistent thoughts
        let combined = "\(city)-\(sentiment)"
        let hash = abs(combined.hashValue)
        
        let thoughtTemplates: [[String]] = [
            ["The weather is perfect today", "Community events are bringing people together", "Local businesses are thriving"],
            ["City infrastructure improvements are noticeable", "Public transportation is running smoothly", "Parks are well-maintained"],
            ["New restaurants and cafes are opening", "Art scene is flourishing", "Tech companies are expanding"],
            ["Neighborhood safety has improved", "Community gardens are blooming", "Local schools showing progress"],
            ["Traffic flow has improved", "Public services are responsive", "Green initiatives are working"],
            ["Housing market is stabilizing", "Job opportunities increasing", "Cultural diversity celebrated"]
        ]
        
        let index = hash % thoughtTemplates.count
        return thoughtTemplates[index]
    }
    
    // Generate consistent cares based on city
    private func generateConsistentCares(for city: String) -> [String] {
        let hash = abs(city.hashValue)
        
        let careTemplates: [[String]] = [
            ["Environment", "Education", "Healthcare", "Safety", "Economy"],
            ["Community", "Culture", "Innovation", "Sustainability", "Growth"],
            ["Transportation", "Housing", "Jobs", "Recreation", "Services"],
            ["Arts", "Technology", "Business", "Wellness", "Development"],
            ["Family", "Future", "Opportunity", "Quality of Life", "Progress"],
            ["Infrastructure", "Climate", "Equality", "Health", "Prosperity"]
        ]
        
        let index = hash % careTemplates.count
        return careTemplates[index]
    }
    
    // Fetch city sentiments - returns consistent data
    func fetchCitySentiments() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // Try to fetch from API first
            let url = URL(string: "https://mainoverallapi.vercel.app")!
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: String],
               let dataString = json["data"],
               let jsonData = dataString.data(using: .utf8),
               let cities = try JSONSerialization.jsonObject(with: jsonData) as? [String: [String: Any]] {
                
                // Process cities with consistent data
                var sentiments: [CitySentiment] = []
                
                for (cityName, _) in cities {
                    let cachedSentiment = cache[cityName] ?? generateConsistentCitySentiment(for: cityName)
                    sentiments.append(cachedSentiment)
                    cache[cityName] = cachedSentiment
                }
                
                await MainActor.run {
                    self.citySentiments = sentiments.sorted { $0.city < $1.city }
                    self.isLoading = false
                    self.saveCachedData()
                }
            }
        } catch {
            // Fallback to cached or generated data
            await MainActor.run {
                if cache.isEmpty {
                    // Generate default cities
                    let defaultCities = ["New York", "San Francisco", "Los Angeles", "Chicago", "Miami", "Boston", "Seattle", "Austin", "Denver", "Portland"]
                    self.citySentiments = defaultCities.map { generateConsistentCitySentiment(for: $0) }
                } else {
                    self.citySentiments = Array(cache.values).sorted { $0.city < $1.city }
                }
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func generateConsistentCitySentiment(for city: String) -> CitySentiment {
        let (emoji, label, intensity) = generateConsistentSentiment(for: city)
        let thoughts = generateConsistentThoughts(for: city, sentiment: label)
        let cares = generateConsistentCares(for: city)
        
        return CitySentiment(
            city: city,
            emoji: emoji,
            label: label,
            intensity: intensity,
            whatPeopleThinking: thoughts,
            whatPeopleCare: cares
        )
    }
    
    // Get consistent sentiment for a specific city
    func getCitySentiment(for city: String) -> CitySentiment {
        if let cached = cache[city] {
            return cached
        }
        
        let sentiment = generateConsistentCitySentiment(for: city)
        cache[city] = sentiment
        saveCachedData()
        return sentiment
    }
    
    // MARK: - Persistence
    
    private func saveCachedData() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(cache) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
    
    private func loadCachedData() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([String: CitySentiment].self, from: data) {
            cache = decoded
        }
    }
}

// Make CitySentiment Codable for caching
extension CitySentiment: Codable {
    enum CodingKeys: String, CodingKey {
        case city, emoji, label, intensity, whatPeopleThinking, whatPeopleCare
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        city = try container.decode(String.self, forKey: .city)
        emoji = try container.decode(String.self, forKey: .emoji)
        label = try container.decode(String.self, forKey: .label)
        intensity = try container.decode(Double.self, forKey: .intensity)
        whatPeopleThinking = try container.decode([String].self, forKey: .whatPeopleThinking)
        whatPeopleCare = try container.decode([String].self, forKey: .whatPeopleCare)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(city, forKey: .city)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(label, forKey: .label)
        try container.encode(intensity, forKey: .intensity)
        try container.encode(whatPeopleThinking, forKey: .whatPeopleThinking)
        try container.encode(whatPeopleCare, forKey: .whatPeopleCare)
    }
}
