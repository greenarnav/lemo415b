//
//  ImprovedForecastService.swift
//  MoodGpt
//
//  Created by Test on 5/8/25.
//


//
//  ImprovedForecastService.swift
//  MoodGpt
//
//  Created by Test on 5/8/25.
//

import SwiftUI

// Improved ForecastService to provide dummy data and support past/future days
class ImprovedForecastService: ObservableObject {
    @Published var forecast: [ImprovedForecastData] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    func fetchForecast(for city: String) {
        isLoading = true
        error = nil
        
        // Generate a 7-day forecast centered on today
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            
            // Get the current date and calendar
            let calendar = Calendar.current
            let today = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "MMM d"
            
            // Generate 7 days of dummy data (3 days before, today, 3 days after)
            var forecastData: [ImprovedForecastData] = []
            
            for dayOffset in -3...3 {
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                    let dayOfWeek = formatter.string(from: date)
                    let dateString = dayFormatter.string(from: date)
                    let isToday = dayOffset == 0
                    
                    // Create varied dummy data for each day
                    let (emoji, label, intensity) = self.getMoodForDay(dayOffset)
                    
                    var forecast = ImprovedForecastData(
                        day: dayOfWeek,
                        date: dateString,
                        emoji: emoji,
                        label: label,
                        isToday: isToday,
                        intensity: intensity
                    )
                    
                    // Add dummy content data
                    forecast.whatPeopleThinking = self.getDummyThoughts(for: label)
                    forecast.whatPeopleCare = self.getDummyCares(for: label)
                    
                    forecastData.append(forecast)
                }
            }
            
            self.forecast = forecastData
        }
    }
    
    // Helper to generate different moods for different days
    private func getMoodForDay(_ offset: Int) -> (emoji: String, label: String, intensity: Double) {
        switch offset {
        case -3:
            return ("😌", "Calm", 0.6)
        case -2:
            return ("😐", "Neutral", 0.5)
        case -1:
            return ("🙂", "Positive", 0.7)
        case 0:
            return ("😊", "Happy", 0.8) // Today is happy!
        case 1:
            return ("😃", "Excited", 0.9)
        case 2:
            return ("😎", "Confident", 0.85)
        case 3:
            return ("😇", "Joyful", 0.95)
        default:
            return ("😐", "Neutral", 0.5)
        }
    }
    
    // Helper for dummy thoughts
    private func getDummyThoughts(for mood: String) -> [String] {
        switch mood.lowercased() {
        case "happy":
            return [
                "The weather today really lifted my spirits",
                "Great community events happening around town",
                "Exciting new restaurant openings"
            ]
        case "excited":
            return [
                "Looking forward to the weekend festival",
                "New tech company moving to town is creating buzz",
                "Sports team had a big win yesterday"
            ]
        case "calm":
            return [
                "Enjoying the peaceful parks around the city",
                "New meditation studio opened downtown",
                "Traffic has been lighter than usual"
            ]
        case "confident":
            return [
                "Local businesses reporting strong growth",
                "City investment in infrastructure showing results",
                "Education initiatives gaining recognition"
            ]
        case "joyful":
            return [
                "Community celebration bringing people together",
                "Perfect weather for outdoor activities",
                "Local artists showcasing their work citywide"
            ]
        case "neutral":
            return [
                "Business as usual around town",
                "Moderate traffic conditions",
                "Average attendance at local events"
            ]
        case "positive":
            return [
                "Small improvements noticed around the city",
                "Slightly better economic outlook",
                "Community initiatives gaining traction"
            ]
        default:
            return [
                "People reflecting on city improvements",
                "Discussions about future developments",
                "Mixed opinions on recent changes"
            ]
        }
    }
    
    // Helper for dummy cares
    private func getDummyCares(for mood: String) -> [String] {
        switch mood.lowercased() {
        case "happy":
            return ["Events", "Food", "Community", "Parks", "Arts"]
        case "excited":
            return ["Festivals", "Sports", "Technology", "Entertainment", "Nightlife"]
        case "calm":
            return ["Parks", "Wellness", "Reading", "Nature", "Relaxation"]
        case "confident":
            return ["Business", "Economy", "Education", "Development", "Innovation"]
        case "joyful":
            return ["Celebrations", "Family", "Art", "Music", "Community"]
        case "neutral":
            return ["Weather", "Traffic", "Services", "News", "Local Issues"]
        case "positive":
            return ["Improvements", "Progress", "Growth", "Community", "Future"]
        default:
            return ["Safety", "Environment", "Transportation", "Housing", "Education"]
        }
    }
}