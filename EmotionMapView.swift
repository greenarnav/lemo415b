import SwiftUI
import MapKit
import CoreLocation

// Our custom city emotion data model
struct MapCityEmotion: Identifiable, Equatable {
    let id = UUID()
    let cityName: String
    let coordinate: CLLocationCoordinate2D
    let emoji: String
    let sentiment: String
    
    static func == (lhs: MapCityEmotion, rhs: MapCityEmotion) -> Bool {
        return lhs.id == rhs.id
    }
}

// Component for the Map itself
struct EnhancedEmotionMapView: View {
    @Binding var region: MKCoordinateRegion
    var cityEmotions: [MapCityEmotion]
    @Binding var userInteractedWithMap: Bool
    var onCitySelected: (MapCityEmotion) -> Void
    
    // State for dynamic pins
    @State private var dynamicCityEmotions: [MapCityEmotion] = []
    
    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: combinedEmotions) { city in
            MapAnnotation(coordinate: city.coordinate) {
                CityMarker(cityData: city)
                    .onTapGesture {
                        region.center = city.coordinate
                        userInteractedWithMap = true
                        onCitySelected(city)
                    }
            }
        }
        .ignoresSafeArea()
        .gesture(
            DragGesture().onChanged { _ in
                userInteractedWithMap = true
                // Generate new pins when dragging
                generateDynamicPins()
            }
        )
        .gesture(
            MagnificationGesture().onChanged { _ in
                userInteractedWithMap = true
                // Generate new pins when zooming
                generateDynamicPins()
            }
        )
        .onAppear {
            // Generate pins when view appears
            generateDynamicPins()
            
            // Generate pins again after a delay to ensure map is loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                generateDynamicPins()
            }
        }
    }
    
    // Combine static and dynamic emotions
    private var combinedEmotions: [MapCityEmotion] {
        return cityEmotions + dynamicCityEmotions
    }
    
    // Generate dynamic pins based on current region
    private func generateDynamicPins() {
        let center = region.center
        let span = region.span
        
        // New York locations - hard-coded for reliability
        let nyLocations: [(name: String, lat: Double, lng: Double)] = [
            ("Central Park", 40.7812, -73.9665),
            ("Times Square", 40.7580, -73.9855),
            ("Brooklyn Heights", 40.6973, -73.9932),
            ("Astoria", 40.7720, -73.9301),
            ("Long Island City", 40.7448, -73.9487),
            ("Flushing", 40.7654, -73.8318),
            ("Forest Hills", 40.7185, -73.8458),
            ("Jamaica", 40.7020, -73.8076),
            ("Long Island", 40.7998, -73.7079),
            ("Coney Island", 40.5755, -73.9707),
            ("Bronx Zoo", 40.8506, -73.8770),
            ("Yankee Stadium", 40.8296, -73.9262),
            ("Staten Island", 40.5795, -74.1502),
            ("Hoboken", 40.7439, -74.0323),
            ("Harlem", 40.8116, -73.9465),
            ("SoHo", 40.7209, -74.0007),
            ("Williamsburg", 40.7081, -73.9571),
            ("Dumbo", 40.7033, -73.9890),
            ("Bushwick", 40.6958, -73.9171),
            ("Midtown", 40.7549, -73.9840)
        ]
        
        // Additional neighborhoods to ensure we have plenty of pins
        let moreLocations: [(name: String, lat: Double, lng: Double)] = [
            ("Battery Park", 40.7033, -74.0170),
            ("Chelsea", 40.7465, -74.0014),
            ("Chinatown", 40.7158, -73.9970),
            ("East Village", 40.7265, -73.9815),
            ("Financial District", 40.7075, -74.0113),
            ("Flatiron District", 40.7410, -73.9896),
            ("Greenwich Village", 40.7335, -74.0083),
            ("Little Italy", 40.7197, -73.9970),
            ("Lower East Side", 40.7168, -73.9861),
            ("Murray Hill", 40.7457, -73.9765),
            ("Tribeca", 40.7163, -74.0086),
            ("Upper East Side", 40.7736, -73.9566),
            ("Upper West Side", 40.7870, -73.9754),
            ("West Village", 40.7347, -74.0085)
        ]
        
        // Combine all locations
        let allLocations = nyLocations + moreLocations
        
        // Define possible sentiments and emojis for consistency
        let emotions: [(sentiment: String, emoji: String)] = [
            ("happy", "😊"),
            ("excited", "🤩"),
            ("calm", "😌"),
            ("neutral", "😐"),
            ("sad", "😢"),
            ("surprised", "😲"),
            ("thoughtful", "🤔"),
            ("confident", "😎"),
            ("anxious", "😰"),
            ("loved", "😍")
        ]
        
        // Filter locations within the visible map region
        var newEmotions: [MapCityEmotion] = []
        
        for location in allLocations {
            let locationCoordinate = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
            
            // Check if location is within the current map view (with some margin)
            if isCoordinateVisible(locationCoordinate, in: region) {
                // Get a consistent emotion for this location
                let emotionIndex = abs(location.name.hashValue) % emotions.count
                let emotion = emotions[emotionIndex]
                
                newEmotions.append(
                    MapCityEmotion(
                        cityName: location.name,
                        coordinate: locationCoordinate,
                        emoji: emotion.emoji,
                        sentiment: emotion.sentiment
                    )
                )
            }
        }
        
        // Add random pins in empty areas if we don't have enough pins
        if newEmotions.count < 5 {
            // Generate some random pins around the current center
            for i in 0..<10 {
                // Random offset from center
                let latOffset = Double.random(in: -span.latitudeDelta/2...span.latitudeDelta/2)
                let lngOffset = Double.random(in: -span.longitudeDelta/2...span.longitudeDelta/2)
                
                let randomCoord = CLLocationCoordinate2D(
                    latitude: center.latitude + latOffset,
                    longitude: center.longitude + lngOffset
                )
                
                // Pick a random emotion
                let emotion = emotions.randomElement()!
                
                // Generate a random location name
                let areaNames = ["Heights", "Park", "Square", "Village", "Hill", "Gardens", "Place"]
                let directions = ["North", "South", "East", "West", "Upper", "Lower"]
                let randomName = "\(directions.randomElement()!) \(areaNames.randomElement()!) \(i+1)"
                
                newEmotions.append(
                    MapCityEmotion(
                        cityName: randomName,
                        coordinate: randomCoord,
                        emoji: emotion.emoji,
                        sentiment: emotion.sentiment
                    )
                )
            }
        }
        
        // Update the dynamic pins
        dynamicCityEmotions = newEmotions
    }
    
    // Helper function to check if a coordinate is within the current map view
    private func isCoordinateVisible(_ coordinate: CLLocationCoordinate2D, in region: MKCoordinateRegion) -> Bool {
        let latDelta = region.span.latitudeDelta / 2.0
        let lngDelta = region.span.longitudeDelta / 2.0
        
        let minLat = region.center.latitude - latDelta
        let maxLat = region.center.latitude + latDelta
        let minLng = region.center.longitude - lngDelta
        let maxLng = region.center.longitude + lngDelta
        
        return coordinate.latitude >= minLat &&
               coordinate.latitude <= maxLat &&
               coordinate.longitude >= minLng &&
               coordinate.longitude <= maxLng
    }
}

// Component for each city's marker on the map
struct CityMarker: View {
    let cityData: MapCityEmotion
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 38, height: 38)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                
                Text(cityData.emoji)
                    .font(.system(size: 24))
            }
            
            Text(cityData.cityName)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.9))
                .cornerRadius(4)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
        }
        .contentShape(Rectangle())
    }
}

// Location button in bottom right corner
struct MapLocationButton: View {
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
            }
        }
    }
}

// Loading indicator
struct MapLoadingIndicator: View {
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
