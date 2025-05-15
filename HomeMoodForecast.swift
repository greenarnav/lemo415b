//
//  HomeForecastService.swift
//  MoodGpt
//
//  Created by Test on 5/7/25.
//

import SwiftUI
import Combine

struct HomeMoodForecast: Identifiable {
    let id = UUID()
    let timeSegment: String  // "Morning", "Afternoon", "Evening", "Night"
    let date: Date
    let emoji: String
    let label: String
    let isCurrentSegment: Bool
    let isPast: Bool
    
    // Computed property to display relative day
    var displayDay: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
    }
}

class HomeForecastService: ObservableObject {
    @Published var forecast: [HomeMoodForecast] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    private let dataFetcher: DataFetcher
    
    // Store generated forecasts to ensure consistency
    private var forecastCache: [String: HomeMoodForecast] = [:]
    
    enum TimeSegment: String, CaseIterable {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        case night = "Night"
        
        static func current(for date: Date = Date()) -> TimeSegment {
            let hour = Calendar.current.component(.hour, from: date)
            switch hour {
            case 5..<12:
                return .morning
            case 12..<17:
                return .afternoon
            case 17..<21:
                return .evening
            default:
                return .night
            }
        }
        
        var order: Int {
            switch self {
            case .morning: return 0
            case .afternoon: return 1
            case .evening: return 2
            case .night: return 3
            }
        }
    }
    
    enum Emotion: CaseIterable {
        case happy
        case sad
        case indifferent
        case angry
        case calm
        case chaotic
        
        var emoji: String {
            switch self {
            case .happy: return "😊"
            case .sad: return "😢"
            case .indifferent: return "😐"
            case .angry: return "😡"
            case .calm: return "😌"
            case .chaotic: return "🤪"
            }
        }
        
        var label: String {
            switch self {
            case .happy: return "Happy"
            case .sad: return "Sad"
            case .indifferent: return "Indifferent"
            case .angry: return "Angry"
            case .calm: return "Calm"
            case .chaotic: return "Chaotic"
            }
        }
    }
    
    init(dataFetcher: DataFetcher = DataFetcher.shared) {
        self.dataFetcher = dataFetcher
        // Load cached forecasts from UserDefaults
        loadCachedForecasts()
    }
    
    func fetchForecast(for city: String) {
        isLoading = true
        error = nil
        
        // Generate time-based forecast segments
        self.forecast = generateTimeBasedForecast()
        self.isLoading = false
        
        // Save generated forecasts
        saveCachedForecasts()
        
        // Optionally still fetch API data to update forecasts
        fetchAPIForecast(for: city)
    }
    
    private func generateTimeBasedForecast() -> [HomeMoodForecast] {
        var segments: [HomeMoodForecast] = []
        let calendar = Calendar.current
        let now = Date()
        let currentSegment = TimeSegment.current(for: now)
        
        // Get all segments for past and future
        let allSegments = TimeSegment.allCases
        var dateToProcess = now
        
        // Generate past segments (3)
        var pastSegments: [HomeMoodForecast] = []
        var currentSegmentIndex = currentSegment.order
        
        // Go back in time to get past segments
        for i in 1...3 {
            currentSegmentIndex -= 1
            if currentSegmentIndex < 0 {
                currentSegmentIndex = 3
                dateToProcess = calendar.date(byAdding: .day, value: -1, to: dateToProcess)!
            }
            
            let segment = allSegments[currentSegmentIndex]
            let key = generateCacheKey(date: dateToProcess, segment: segment)
            
            // Check if we already have this forecast cached
            if let cachedForecast = forecastCache[key] {
                pastSegments.append(cachedForecast)
            } else {
                // Generate new forecast with deterministic emotion
                let emotion = generateDeterministicEmotion(date: dateToProcess, segment: segment)
                let forecast = HomeMoodForecast(
                    timeSegment: segment.rawValue,
                    date: dateToProcess,
                    emoji: emotion.emoji,
                    label: emotion.label,
                    isCurrentSegment: false,
                    isPast: true
                )
                forecastCache[key] = forecast
                pastSegments.append(forecast)
            }
        }
        
        // Add past segments in correct order (oldest to newest)
        segments.append(contentsOf: pastSegments.reversed())
        
        // Add current segment
        let currentKey = generateCacheKey(date: now, segment: currentSegment)
        if let cachedCurrent = forecastCache[currentKey] {
            segments.append(cachedCurrent)
        } else {
            let currentEmotion = generateDeterministicEmotion(date: now, segment: currentSegment)
            let currentForecast = HomeMoodForecast(
                timeSegment: currentSegment.rawValue,
                date: now,
                emoji: currentEmotion.emoji,
                label: currentEmotion.label,
                isCurrentSegment: true,
                isPast: false
            )
            forecastCache[currentKey] = currentForecast
            segments.append(currentForecast)
        }
        
        // Generate future segments (3)
        dateToProcess = now
        currentSegmentIndex = currentSegment.order
        
        for i in 1...3 {
            currentSegmentIndex += 1
            if currentSegmentIndex > 3 {
                currentSegmentIndex = 0
                dateToProcess = calendar.date(byAdding: .day, value: 1, to: dateToProcess)!
            }
            
            let segment = allSegments[currentSegmentIndex]
            let key = generateCacheKey(date: dateToProcess, segment: segment)
            
            // Check if we already have this forecast cached
            if let cachedForecast = forecastCache[key] {
                segments.append(cachedForecast)
            } else {
                // Generate new forecast with deterministic emotion
                let emotion = generateDeterministicEmotion(date: dateToProcess, segment: segment)
                let forecast = HomeMoodForecast(
                    timeSegment: segment.rawValue,
                    date: dateToProcess,
                    emoji: emotion.emoji,
                    label: emotion.label,
                    isCurrentSegment: false,
                    isPast: false
                )
                forecastCache[key] = forecast
                segments.append(forecast)
            }
        }
        
        return segments
    }
    
    // Generate a deterministic emotion based on date and segment
    private func generateDeterministicEmotion(date: Date, segment: TimeSegment) -> Emotion {
        // Create a seed based on the date and segment
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let seed = (components.year ?? 0) * 10000 +
                  (components.month ?? 0) * 100 +
                  (components.day ?? 0) +
                  segment.order
        
        // Use the seed to deterministically select an emotion
        let emotions = Emotion.allCases
        let index = abs(seed) % emotions.count
        return emotions[index]
    }
    
    // Generate a cache key for a specific date and segment
    private func generateCacheKey(date: Date, segment: TimeSegment) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)-\(segment.rawValue)"
    }
    
    // Save cached forecasts to UserDefaults
    private func saveCachedForecasts() {
        // Convert forecast cache to a format that can be saved
        var cacheData: [String: [String: Any]] = [:]
        
        for (key, forecast) in forecastCache {
            cacheData[key] = [
                "timeSegment": forecast.timeSegment,
                "date": forecast.date.timeIntervalSince1970,
                "emoji": forecast.emoji,
                "label": forecast.label,
                "isCurrentSegment": forecast.isCurrentSegment,
                "isPast": forecast.isPast
            ]
        }
        
        UserDefaults.standard.set(cacheData, forKey: "forecastCache")
    }
    
    // Load cached forecasts from UserDefaults
    private func loadCachedForecasts() {
        guard let cacheData = UserDefaults.standard.dictionary(forKey: "forecastCache") else { return }
        
        forecastCache.removeAll()
        
        for (key, value) in cacheData {
            if let forecastData = value as? [String: Any],
               let timeSegment = forecastData["timeSegment"] as? String,
               let dateInterval = forecastData["date"] as? TimeInterval,
               let emoji = forecastData["emoji"] as? String,
               let label = forecastData["label"] as? String,
               let isCurrentSegment = forecastData["isCurrentSegment"] as? Bool,
               let isPast = forecastData["isPast"] as? Bool {
                
                let forecast = HomeMoodForecast(
                    timeSegment: timeSegment,
                    date: Date(timeIntervalSince1970: dateInterval),
                    emoji: emoji,
                    label: label,
                    isCurrentSegment: isCurrentSegment,
                    isPast: isPast
                )
                
                forecastCache[key] = forecast
            }
        }
    }
    
    private func fetchAPIForecast(for city: String) {
        // Keep existing API integration for actual data
        dataFetcher.fetchMoodForecast(city: city) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let apiForecasts):
                    // Map API data to our time-based segments if available
                    // For now, we'll keep the generated data
                    break
                case .failure(let err):
                    // Keep the generated fallback data
                    print("API error, using generated data: \(err.localizedDescription)")
                }
            }
        }
    }
}
