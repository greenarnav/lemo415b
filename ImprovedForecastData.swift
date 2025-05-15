//
//  ImprovedForecastData.swift
//  MoodGpt
//
//  Created by Test on 5/8/25.
//


//
//  ImprovedForecastData.swift
//  MoodGpt
//
//  Created by Test on 5/8/25.
//

import SwiftUI

// ImprovedForecastData model with navigation support
struct ImprovedForecastData: Identifiable {
    let id = UUID()
    let day: String
    let date: String
    let emoji: String
    let label: String
    let isToday: Bool
    // Add more detailed data that will be needed for the detail screen
    var whatPeopleThinking: [String] = []
    var whatPeopleCare: [String] = []
    var intensity: Double = 0.7
    
    // Helper to create a CitySentiment from this forecast data
    func toCitySentiment(cityName: String) -> CitySentiment {
        return CitySentiment(
            city: cityName,
            emoji: emoji,
            label: label,
            intensity: intensity,
            whatPeopleThinking: whatPeopleThinking,
            whatPeopleCare: whatPeopleCare
        )
    }
}