//
//  ImprovedForecastBarView.swift
//  MoodGpt
//
//  Created by Test on 5/8/25.
//

import SwiftUI

struct ImprovedForecastBarView: View {
    @ObservedObject var forecastService: ImprovedForecastService
    let cityName: String
    @Binding var selectedForecast: ImprovedForecastData?
    @Binding var showingDetail: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("7-Day Mood Forecast")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            if forecastService.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                }
                .frame(height: 100)
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
                .padding(.horizontal)
            } else if let error = forecastService.error {
                Text("Failed to load forecast: \(error)")
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(forecastService.forecast) { mood in
                            NavigationLink(destination: ForecastDetailView(
                                cityName: cityName,
                                forecast: mood.toHomeMoodForecast()
                            )) {
                                VStack(spacing: 4) {
                                    Text(mood.day)
                                        .font(.caption)
                                        .fontWeight(mood.isToday ? .bold : .regular)
                                        .foregroundColor(.white)
                                    
                                    Text(mood.date)
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text(mood.emoji)
                                        .font(.title2)
                                    
                                    Text(mood.label)
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 72, height: 100)
                                .background(mood.isToday ? Color.white.opacity(0.25) : Color.white.opacity(0.15))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            forecastService.fetchForecast(for: cityName)
        }
    }
}

// Extension to convert ImprovedForecastData to HomeMoodForecast
extension ImprovedForecastData {
    func toHomeMoodForecast() -> HomeMoodForecast {
        return HomeMoodForecast(
            timeSegment: "Day", // Default since ImprovedForecastData doesn't have time segments
            date: Date(), // You might want to parse the date string properly
            emoji: emoji,
            label: label,
            isCurrentSegment: isToday,
            isPast: false // You might want to determine this based on the date
        )
    }
}
