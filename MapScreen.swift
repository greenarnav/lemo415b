import SwiftUI
import MapKit
import CoreLocation

struct MapScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var cityEmotions: [MapCityEmotion] = []
    @State private var isLoading = true
    @State private var showPermissionAlert = false
    @State private var userInteractedWithMap = false
    @State private var selectedCity: CitySentiment? = nil
    @State private var lastRefreshTime = Date()
    
    @State private var showCityDetail = false
    @State private var selectedMapCity: MapCityEmotion? = nil
    
    private let refreshInterval: TimeInterval = 300
    @State private var refreshTimer: Timer?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map with city emotion annotations
                EnhancedEmotionMapView(
                    region: $region,
                    cityEmotions: cityEmotions,
                    userInteractedWithMap: $userInteractedWithMap,
                    onCitySelected: { city in
                        selectedMapCity = city
                        showCityDetail = true
                        
                        EnhancedTrackingService.shared.trackTap(
                            screenName: "MapScreen",
                            elementName: "CityMarker-\(city.cityName)"
                        )
                    }
                )
                
                VStack {
                    Spacer()
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.5)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                }
                .ignoresSafeArea()
                
                MapScreenLocationButton(action: requestAndCenterOnUserLocation)
                
                if isLoading {
                    MapScreenLoadingIndicator()
                }
                
                VStack {
                    HStack {
                        Text("Last updated: \(timeAgoString(from: lastRefreshTime))")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                        
                        Spacer()
                        
                        Button(action: {
                            refreshCityData()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(10)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationDestination(item: $selectedCity) { city in
                CityDetailScreen(city: city)
            }
            .sheet(isPresented: $showCityDetail, onDismiss: {
                selectedMapCity = nil
            }) {
                if let city = selectedMapCity {
                    NavigationStack {
                        CityDetailScreen(
                            city: CitySentiment(
                                city: city.cityName,
                                emoji: city.emoji,
                                label: city.sentiment,
                                intensity: getIntensityForSentiment(city.sentiment)
                            )
                        )
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showCityDetail = false
                                }
                            }
                        }
                    }
                }
            }
            .alert("Location Access Required", isPresented: $showPermissionAlert) {
                Button("Settings", role: .none) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please allow location access to see your position on the map and get local sentiment data.")
            }
            .navigationTitle(appState.locationManager.cityName.isEmpty ? "Locating…" : appState.locationManager.cityName)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                requestAndCenterOnUserLocation()
                loadCityEmotions()
                setupRefreshTimer()
                
                EnhancedTrackingService.shared.trackScreenView("MapScreen")
                
                if appState.locationManager.authorizationStatus == .denied ||
                   appState.locationManager.authorizationStatus == .restricted {
                    showPermissionAlert = true
                }
            }
            .onDisappear {
                refreshTimer?.invalidate()
                refreshTimer = nil
            }
            .onChange(of: appState.locationManager.userLocation) { oldValue, newValue in
                if let newLocation = newValue, !userInteractedWithMap {
                    print("New user location received: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
                    withAnimation {
                        region = MKCoordinateRegion(
                            center: newLocation.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    }
                }
            }
            .onChange(of: appState.locationManager.authorizationStatus) { oldValue, newValue in
                if newValue == .authorizedWhenInUse || newValue == .authorizedAlways {
                    requestAndCenterOnUserLocation()
                } else if newValue == .denied || newValue == .restricted {
                    showPermissionAlert = true
                }
            }
            .trackSwipes(screenName: "MapScreen")
        }
    }
    
    private func setupRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
            print("Auto-refreshing map data")
            refreshCityData()
        }
    }
    
    private func refreshCityData() {
        isLoading = true
        
        EnhancedTrackingService.shared.trackButtonClick(
            screenName: "MapScreen",
            buttonName: "RefreshData"
        )
        
        loadCityEmotions()
    }
    
    private func requestAndCenterOnUserLocation() {
        userInteractedWithMap = false
        
        appState.locationManager.requestLocationPermission()
        
        if let location = appState.locationManager.userLocation {
            print("Using existing location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            withAnimation {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        } else {
            withAnimation {
                region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
    }
    
    private func loadCityEmotions() {
        isLoading = true
        
        Task {
            let baseEmotions = generateBaseEmotions()
            
            DispatchQueue.main.async {
                self.cityEmotions = baseEmotions
                self.lastRefreshTime = Date()
                self.isLoading = false
            }
        }
    }
    
    private func generateBaseEmotions() -> [MapCityEmotion] {
        let majorAreas: [(name: String, lat: Double, lng: Double)] = [
            ("Manhattan", 40.7831, -73.9712),
            ("Brooklyn", 40.6782, -73.9442),
            ("Queens", 40.7282, -73.7949),
            ("The Bronx", 40.8448, -73.8648),
            ("Staten Island", 40.5795, -74.1502),
            ("Jersey City", 40.7178, -74.0431),
            ("Hoboken", 40.7439, -74.0323),
            ("Long Island", 40.7891, -73.1350)
        ]
        
        let sentiments: [(mood: String, emoji: String)] = [
            ("happy", "😊"),
            ("excited", "🤩"),
            ("calm", "😌"),
            ("neutral", "😐"),
            ("sad", "😢"),
            ("surprised", "😲"),
            ("thoughtful", "🤔"),
            ("confident", "😎")
        ]
        
        return majorAreas.map { area in
            let nameHash = area.name.hashValue
            let sentimentIndex = abs(nameHash) % sentiments.count
            let sentiment = sentiments[sentimentIndex]
            
            return MapCityEmotion(
                cityName: area.name,
                coordinate: CLLocationCoordinate2D(latitude: area.lat, longitude: area.lng),
                emoji: sentiment.emoji,
                sentiment: sentiment.mood
            )
        }
    }
    
    private func getIntensityForSentiment(_ sentiment: String) -> Double {
        switch sentiment.lowercased() {
        case "happy", "excited", "joyful":
            return 0.8
        case "calm", "confident":
            return 0.7
        case "neutral", "thoughtful":
            return 0.5
        case "sad", "angry":
            return 0.3
        default:
            return 0.5
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct MapScreenLocationButton: View {
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .padding(14)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 2)
                }
                .padding([.trailing, .bottom], 16)
                .trackButtonClick(screenName: "MapScreen", buttonName: "LocationButton")
            }
        }
    }
}

struct MapScreenLoadingIndicator: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.9))
                .shadow(radius: 4)
                .frame(width: 120, height: 120)
            
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Loading Map")
                    .font(.callout)
                    .foregroundColor(.black.opacity(0.7))
            }
        }
    }
}
