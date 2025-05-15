// Updated HomeScreenViewModel using consistent sentiment service

import SwiftUI
import Combine

@MainActor
final class HomeScreenViewModel: ObservableObject {
    // MARK: - Published state
    @Published var allCities: [CitySentiment] = []
    @Published var favorite: [CitySentiment] = []
    @Published var isLoading = true
    @Published var errorMessage: String? = nil
    @Published var lastUpdated = Date()
    
    private let sentimentService = ConsistentCitySentimentService.shared
    
    init() {
        // Load favorites when the view model is initialized
        loadFavorites()
    }
    
    // MARK: - Public API
    func fetch() {
        isLoading = true
        
        Task {
            await sentimentService.fetchCitySentiments()
            
            await MainActor.run {
                self.allCities = sentimentService.citySentiments
                self.updateFavoritesWithLatestData()
                self.errorMessage = sentimentService.error
                self.isLoading = false
                self.lastUpdated = Date()
            }
        }
    }
    
    func toggleFavorite(_ city: CitySentiment) {
        if let idx = favorite.firstIndex(where: { $0.city == city.city }) {
            favorite.remove(at: idx)
        } else {
            favorite.append(city)
        }
        
        // Save favorites after any change
        saveFavorites()
    }
    
    // MARK: - Persistence Methods
    
    // Save favorites to UserDefaults
    private func saveFavorites() {
        // We need to save city names since the CitySentiment objects themselves
        // aren't directly Codable
        let favoriteCityNames = favorite.map { $0.city }
        UserDefaults.standard.set(favoriteCityNames, forKey: "favoriteCities")
    }
    
    // Load favorites from UserDefaults
    private func loadFavorites() {
        if let favoriteCityNames = UserDefaults.standard.array(forKey: "favoriteCities") as? [String] {
            // We'll restore the full CitySentiment objects when we have loaded allCities
            // For now, just store the city names
            self.favorite = favoriteCityNames.compactMap { cityName in
                if let existingCity = allCities.first(where: { $0.city == cityName }) {
                    return existingCity
                }
                return nil
            }
        }
    }
    
    // Update favorites with the latest data after fetching
    private func updateFavoritesWithLatestData() {
        // Get the names of the currently favorited cities
        let favoriteCityNames = favorite.map { $0.city }
        
        // Clear the current favorites
        favorite.removeAll()
        
        // Rebuild the favorites array with the latest city data
        for cityName in favoriteCityNames {
            if let updatedCity = allCities.first(where: { $0.city == cityName }) {
                favorite.append(updatedCity)
            }
        }
        
        // Re-save the favorites (though this is technically redundant since the names haven't changed)
        saveFavorites()
    }
}
