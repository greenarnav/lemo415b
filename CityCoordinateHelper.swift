//
//  CityCordinateHelper.swift
//  MoodGpt
//
//  Created by Test on 5/7/25.
//

import CoreLocation

// Helper class for city coordinates
struct CityCoordinateHelper {
    // Static method to get coordinates for city names
    static func getCoordinateForCity(_ cityName: String) -> CLLocationCoordinate2D {
        // In a real app, you would use a geocoding service or database
        // For now, hardcoding some common locations
        let cityCoordinates: [String: CLLocationCoordinate2D] = [
            // New York metro area
            "new york": CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            "brooklyn": CLLocationCoordinate2D(latitude: 40.6782, longitude: -73.9442),
            "queens": CLLocationCoordinate2D(latitude: 40.7282, longitude: -73.7949),
            "bronx": CLLocationCoordinate2D(latitude: 40.8448, longitude: -73.8648),
            "staten island": CLLocationCoordinate2D(latitude: 40.5795, longitude: -74.1502),
            "jersey city": CLLocationCoordinate2D(latitude: 40.7178, longitude: -74.0431),
            "newark": CLLocationCoordinate2D(latitude: 40.7357, longitude: -74.1724),
            "yonkers": CLLocationCoordinate2D(latitude: 40.9312, longitude: -73.8987),
            "hoboken": CLLocationCoordinate2D(latitude: 40.7439, longitude: -74.0323),
            
            // Other major cities
            "san francisco": CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            "los angeles": CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
            "chicago": CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298),
            "seattle": CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
            "miami": CLLocationCoordinate2D(latitude: 25.7617, longitude: -80.1918),
            "austin": CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431),
            "denver": CLLocationCoordinate2D(latitude: 39.7392, longitude: -104.9903),
            "boston": CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589),
            "philadelphia": CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652),
            "washington dc": CLLocationCoordinate2D(latitude: 38.9072, longitude: -77.0369),
            "atlanta": CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880),
            "dallas": CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970),
            "houston": CLLocationCoordinate2D(latitude: 29.7604, longitude: -95.3698),
            "phoenix": CLLocationCoordinate2D(latitude: 33.4484, longitude: -112.0740),
            "san diego": CLLocationCoordinate2D(latitude: 32.7157, longitude: -117.1611),
            "las vegas": CLLocationCoordinate2D(latitude: 36.1699, longitude: -115.1398),
            "portland": CLLocationCoordinate2D(latitude: 45.5051, longitude: -122.6750),
            "nashville": CLLocationCoordinate2D(latitude: 36.1627, longitude: -86.7816),
            "new orleans": CLLocationCoordinate2D(latitude: 29.9511, longitude: -90.0715)
        ]
        
        // Look for case-insensitive match
        let normalizedName = cityName.lowercased()
        if let coordinate = cityCoordinates[normalizedName] {
            return coordinate
        }
        
        // Try partial matches
        for (key, coordinate) in cityCoordinates {
            if normalizedName.contains(key) || key.contains(normalizedName) {
                return coordinate
            }
        }
        
        // Default to New York if no match found
        return CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    }
}
