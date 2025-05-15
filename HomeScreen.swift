// HomeScreen.swift
import SwiftUI

struct HomeScreen: View {
    // MARK: - State
    @StateObject private var vm = HomeScreenViewModel()
    @StateObject private var locationService = HomeScreenLocationService()
    @StateObject private var forecastService = HomeForecastService()
    @StateObject private var contactsViewModel = ContactsViewModel()
    @State private var searchText = ""
    @State private var currentPage = 0
    
    private let perPage = 3
    
    // MARK: - Get top 5 cities by contact count
    private var topContactCities: [(city: String, count: Int)] {
        // Count contacts per city
        let cityCounts = Dictionary(grouping: contactsViewModel.rows.filter { $0.hasLocation }, by: { $0.city })
            .mapValues { $0.count }
        
        // Sort by count and get top 5
        return cityCounts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { (city: $0.key, count: $0.value) }
    }
    
    // MARK: - Filter cities based on top contact cities
    private var contactCities: Set<String> {
        Set(topContactCities.map { $0.city })
    }
    
    // MARK: - Derived data
    private var filtered: [CitySentiment] {
        // First filter by contact cities, then by search text
        let citiesWithContacts = vm.allCities.filter { city in
            contactCities.contains(city.city)
        }
        
        if searchText.isEmpty {
            return citiesWithContacts
        } else {
            return citiesWithContacts.filter { $0.city.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    private var page: [CitySentiment] {
        let start = currentPage * perPage
        let end = min(start + perPage, filtered.count)
        return start < filtered.count ? Array(filtered[start..<end]) : []
    }
    
    private var totalPages: Int {
        max(1, (filtered.count + perPage - 1) / perPage)
    }
    
    // MARK: - View body
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.5), .white.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()
                
                if vm.isLoading || contactsViewModel.loading {
                    ProgressView("Loading…")
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                } else if let msg = vm.errorMessage {
                    VStack(spacing: 12) {
                        Text("Failed to load")
                        Text(msg).font(.caption2)
                        Button("Retry") {
                            vm.fetch()
                            contactsViewModel.load()
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                } else {
                    mainContentView
                }
            }
            .navigationBarHidden(true)
            .task {
                vm.fetch()
                contactsViewModel.load()
                locationService.requestLocation()
            }
            .refreshable {
                vm.fetch()
                contactsViewModel.load()
                locationService.requestLocation()
            }
        }
    }
    
    // MARK: - Main content stack
    private var mainContentView: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "location.fill")
                Text("Cities Mood").font(.title2)
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal)
            
            // Current location
            if let cityMatch = vm.allCities.first(where: {
                $0.city.lowercased() == locationService.currentCity.lowercased()
            }) {
                NavigationLink(destination: CityDetailPage(city: cityMatch)) {
                    HomeLocationCardView(city: cityMatch)
                }
                .buttonStyle(PlainButtonStyle())
            } else if let first = filtered.first {
                NavigationLink(destination: CityDetailPage(city: first)) {
                    HomeLocationCardView(city: first)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Text("No city data available")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(16)
                    .padding(.horizontal)
            }
            
            Text("Your location: \(locationService.currentCity)")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            // Forecast
            HomeForecastBarView(
                forecastService: forecastService,
                cityName: locationService.currentCity
            )
            
            // Search
            HomeSearchView(
                searchText: $searchText,
                onClear: {
                    searchText = ""
                    currentPage = 0
                }
            )
            
            // Friend Cities header
            HStack {
                Text("Friend Cities")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(topContactCities.count) cities")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal)
            
            // Top cities list
            if topContactCities.isEmpty {
                Text("No cities with contacts found")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(topContactCities, id: \.city) { cityData in
                            if let citySentiment = vm.allCities.first(where: { $0.city == cityData.city }) {
                                NavigationLink(destination: CityDetailPage(city: citySentiment)) {
                                    CityContactCard(
                                        city: citySentiment,
                                        contactCount: cityData.count
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                // Show placeholder card for cities without sentiment data no
                                PlaceholderCityCard(
                                    cityName: cityData.city,
                                    contactCount: cityData.count
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding(.top)
        .animation(.easeInOut, value: filtered.count)
    }
}

// City card showing contact count
struct CityContactCard: View {
    let city: CitySentiment
    let contactCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // City emoji and info
            HStack(spacing: 12) {
                Text(city.emoji)
                    .font(.system(size: 48))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(city.city)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(city.label)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    // Show what people are thinking (first item)
                    if let firstThought = city.whatPeopleThinking.first {
                        Text(firstThought)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Contact count badge
            VStack {
                Text("\(contactCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("contacts")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [EmotionTheme.cardColor(for: city.label).opacity(0.6), .black.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}

// Placeholder card for cities without sentiment data
struct PlaceholderCityCard: View {
    let cityName: String
    let contactCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // City emoji and info
            HStack(spacing: 12) {
                Text("🏙️")
                    .font(.system(size: 48))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(cityName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("No mood data")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Contact count badge
            VStack {
                Text("\(contactCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("contacts")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.3))
        .cornerRadius(16)
    }
}
