//
//  CityDetailScreen.swift
//  MoodGpt
//

import SwiftUI

// Local type to avoid namespace issues
fileprivate struct LocalCitySentiment: Identifiable, Hashable {
    let id = UUID()
    let city: String
    let emoji: String
    let label: String
    let intensity: Double
    var whatPeopleThinking: [String] = []
    var whatPeopleCare: [String] = []
    var date: String? = nil // Optional date for when coming from forecast
    
    static func == (lhs: LocalCitySentiment, rhs: LocalCitySentiment) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Converter from the global CitySentiment to local version
    init(from citySentiment: CitySentiment, date: String? = nil) {
        self.city = citySentiment.city
        self.emoji = citySentiment.emoji
        self.label = citySentiment.label
        self.intensity = citySentiment.intensity
        self.whatPeopleThinking = citySentiment.whatPeopleThinking
        self.whatPeopleCare = citySentiment.whatPeopleCare
        self.date = date
    }
}

struct CityDetailScreen: View {
    // Use the original type in the public interface
    let city: CitySentiment
    var date: String? = nil // Optional parameter to show the date when coming from forecast
    
    // Private property to convert to our local type
    private var localCity: LocalCitySentiment {
        LocalCitySentiment(from: city, date: date)
    }
    
    var body: some View {
        // Use the same background gradient as the HomeScreen for consistency
        ZStack {
            // Dynamic background gradient based on city emotion
            LinearGradient(
                gradient: Gradient(colors: EmotionTheme.gradientColors(for: localCity.label)),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with city name and date if available
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localCity.city)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(EmotionTheme.textColor(for: localCity.label))
                        
                        if let date = localCity.date {
                            Text(date)
                                .font(.headline)
                                .foregroundColor(EmotionTheme.textColor(for: localCity.label).opacity(0.8))
                        }
                    }
                    
                    // Mood indicator
                    HStack(spacing: 16) {
                        Text(localCity.emoji)
                            .font(.system(size: 64))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Mood: \(localCity.label)")
                                .font(.title3)
                                .foregroundColor(EmotionTheme.textColor(for: localCity.label))
                            
                            ProgressView(value: localCity.intensity)
                                .progressViewStyle(LinearProgressViewStyle(tint: EmotionTheme.cardColor(for: localCity.label)))
                        }
                    }
                    .padding()
                    .background(EmotionTheme.cardColor(for: localCity.label).opacity(0.3))
                    .cornerRadius(12)
                    
                    // What people are thinking
                    Text("What are people thinking")
                        .font(.title3)
                        .foregroundColor(EmotionTheme.textColor(for: localCity.label))
                        .padding(.top)
                    
                    if localCity.whatPeopleThinking.isEmpty {
                        Text("No thoughts recorded for this day.")
                            .foregroundColor(EmotionTheme.textColor(for: localCity.label).opacity(0.7))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(EmotionTheme.cardColor(for: localCity.label).opacity(0.2))
                            .cornerRadius(10)
                    } else {
                        ForEach(localCity.whatPeopleThinking, id: \.self) { idea in
                            Text(idea)
                                .padding()
                                .background(EmotionTheme.cardColor(for: localCity.label))
                                .cornerRadius(10)
                        }
                    }
                    
                    // What people care about
                    Text("What people care about")
                        .font(.title3)
                        .foregroundColor(EmotionTheme.textColor(for: localCity.label))
                    
                    if localCity.whatPeopleCare.isEmpty {
                        Text("No concerns recorded for this day.")
                            .foregroundColor(EmotionTheme.textColor(for: localCity.label).opacity(0.7))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(EmotionTheme.cardColor(for: localCity.label).opacity(0.2))
                            .cornerRadius(10)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(localCity.whatPeopleCare, id: \.self) { cat in
                                    Text(cat)
                                        .padding(8)
                                        .background(EmotionTheme.cardColor(for: localCity.label))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle(localCity.city)
        .navigationBarTitleDisplayMode(.inline)
    }
}
