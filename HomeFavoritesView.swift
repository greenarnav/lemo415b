// Updated HomeFavoritesView.swift with navigation
import SwiftUI

struct HomeFavoritesView: View {
    let favorites: [CitySentiment]
    // Add default value to maintain compatibility with existing code
    let onFavoriteSelected: (CitySentiment) -> Void
    
    // Add initializer with default parameter
    init(
        favorites: [CitySentiment],
        onFavoriteSelected: @escaping (CitySentiment) -> Void = { _ in }
    ) {
        self.favorites = favorites
        self.onFavoriteSelected = onFavoriteSelected
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Favorites").font(.headline).foregroundColor(.white).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(favorites) { city in
                        NavigationLink(destination: CityDetailPage(city: city)) {
                            HStack {
                                Text(city.emoji)
                                Text(city.city).font(.subheadline)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(EmotionTheme.cardColor(for: city.label).opacity(0.3))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .simultaneousGesture(TapGesture().onEnded {
                            // Also call the callback for in-app navigation
                            onFavoriteSelected(city)
                        })
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
