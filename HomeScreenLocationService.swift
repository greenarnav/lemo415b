//
//  HomeScreenLocationService.swift
//  MoodGpt
//
//  Created by Test on 5/7/25.
//


// HomeScreenLocationService.swift
import SwiftUI
import CoreLocation

class HomeScreenLocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var currentCity: String = "New York" // Default fallback city
    @Published var isLoading: Bool = true
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location
            fetchCityName(from: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        isLoading = false
        // Keep fallback to New York
    }
    
    private func fetchCityName(from location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Geocoding error: \(error.localizedDescription)")
                    // Keep fallback to New York
                    return
                }
                
                if let placemark = placemarks?.first, let city = placemark.locality {
                    self.currentCity = city
                }
                // If no city found, keep fallback to New York
            }
        }
    }
}