//
//  HomeForecastBarView.swift
//  MoodGpt
//
//  Created by Test on 5/7/25.
//

import SwiftUI

struct HomeForecastBarView: View {
    @ObservedObject var forecastService: HomeForecastService
    let cityName: String
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mood Timeline")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            if forecastService.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 120)
            } else if let error = forecastService.error {
                Text("Failed to load forecast: \(error)")
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(forecastService.forecast.indices, id: \.self) { index in
                                let mood = forecastService.forecast[index]
                                NavigationLink(destination: ForecastDetailView(
                                    cityName: cityName,
                                    forecast: mood
                                )) {
                                    VStack(spacing: 6) {
                                        // Day label
                                        Text(mood.displayDay)
                                            .font(.caption2)
                                            .fontWeight(mood.isCurrentSegment ? .bold : .regular)
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        // Time segment
                                        Text(mood.timeSegment)
                                            .font(.caption)
                                            .fontWeight(mood.isCurrentSegment ? .bold : .medium)
                                            .foregroundColor(.white)
                                        
                                        // Emoji
                                        Text(mood.emoji)
                                            .font(.title2)
                                        
                                        // Mood label
                                        Text(mood.label)
                                            .font(.caption2)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        // Current indicator
                                        if mood.isCurrentSegment {
                                            Text("NOW")
                                                .font(.caption2)
                                                .bold()
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.white.opacity(0.3))
                                                .cornerRadius(4)
                                        }
                                    }
                                    .frame(width: 80, height: 120)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                mood.isCurrentSegment
                                                ? Color.white.opacity(0.25)
                                                : Color.white.opacity(0.15)
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                mood.isCurrentSegment ? Color.white.opacity(0.5) : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                                    .id(index)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                    .onAppear {
                        // Scroll to the current segment (center it)
                        if let currentIndex = forecastService.forecast.firstIndex(where: { $0.isCurrentSegment }) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo(currentIndex, anchor: .center)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            forecastService.fetchForecast(for: cityName)
        }
    }
}
