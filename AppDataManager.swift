//
//  AppDataManager.swift
//  MoodGpt
//
//  Created by Test on 5/11/25.
//


import SwiftUI
import Combine

// MARK: - Shared App Data Manager
class AppDataManager: ObservableObject {
    static let shared = AppDataManager()
    
    @Published var contactCities: Set<String> = []
    @Published var citySentiments: [CitySentiment] = []
    
    private init() {}
    
    // Update contact cities from ContactsViewModel
    func updateContactCities(from contacts: [ContactsViewModel.Row]) {
        let cities = contacts
            .filter { $0.hasLocation }
            .map { $0.city }
        self.contactCities = Set(cities)
    }
    
    // Update city sentiments from HomeScreenViewModel
    func updateCitySentiments(_ sentiments: [CitySentiment]) {
        self.citySentiments = sentiments
    }
    
    // Get filtered cities based on contacts
    func getFilteredCities() -> [CitySentiment] {
        return citySentiments.filter { city in
            contactCities.contains(city.city)
        }
    }
}