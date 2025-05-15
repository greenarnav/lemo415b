// Updated HomeCityCardsView.swift with clickable cards
import SwiftUI

struct HomeCityCardsView: View {
    let cities: [CitySentiment]
    let currentPage: Int
    let totalPages: Int
    let onPreviousPage: () -> Void
    let onNextPage: () -> Void
    let onToggleFavorite: (CitySentiment) -> Void
    let isFavorite: (CitySentiment) -> Bool
    // Add optional parameter with default value to maintain compatibility
    let onCitySelected: (CitySentiment) -> Void
    
    // Add initializer with default parameter to keep backward compatibility
    init(
        cities: [CitySentiment],
        currentPage: Int,
        totalPages: Int,
        onPreviousPage: @escaping () -> Void,
        onNextPage: @escaping () -> Void,
        onToggleFavorite: @escaping (CitySentiment) -> Void,
        isFavorite: @escaping (CitySentiment) -> Bool,
        onCitySelected: @escaping (CitySentiment) -> Void = { _ in }
    ) {
        self.cities = cities
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.onPreviousPage = onPreviousPage
        self.onNextPage = onNextPage
        self.onToggleFavorite = onToggleFavorite
        self.isFavorite = isFavorite
        self.onCitySelected = onCitySelected
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("City Sentiments").font(.headline).foregroundColor(.white)
                Spacer()
                if !cities.isEmpty {
                    Text("\(currentPage + 1) of \(totalPages)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal)
            
            if cities.isEmpty {
                Text("No cities match your search")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(cities) { city in
                            NavigationLink(destination: CityDetailPage(city: city)) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text(city.emoji).font(.largeTitle)
                                        Spacer()
                                        Button(action: {
                                            onToggleFavorite(city)
                                        }) {
                                            Image(systemName: isFavorite(city) ? "star.fill" : "star")
                                                .foregroundColor(.yellow)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                    Spacer()
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(city.city).bold().foregroundColor(.white)
                                        Text(city.label).foregroundColor(.white.opacity(0.8))
                                        ProgressView(value: city.intensity)
                                            .progressViewStyle(LinearProgressViewStyle(tint: EmotionTheme.cardColor(for: city.label)))
                                    }
                                }
                                .padding()
                                .frame(width: 180, height: 160)
                                .background(
                                    LinearGradient(
                                        colors: [EmotionTheme.cardColor(for: city.label).opacity(0.6), .black.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Page controls
                HStack {
                    Button(action: onPreviousPage) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(currentPage == 0)
                    Spacer()
                    Button(action: onNextPage) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(currentPage >= totalPages - 1)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 40)
            }
        }
    }
}
