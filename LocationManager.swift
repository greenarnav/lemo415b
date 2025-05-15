// LocationManager.swift
import Foundation
import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let apiService = ApiIntegrationService.shared

    @Published var userLocation: CLLocation?
    @Published var equatableLocation: EquatableCoordinate?
    @Published var cityName: String = ""
    @Published var stateName: String = ""
    @Published var areaCode: String = ""
    @Published var isLocationFetched: Bool = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private var lastTrackedLocation: CLLocation?
    private let trackingDistanceThreshold: Double = 100
    private var trackingTimer: Timer?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 100
        
        startPeriodicTracking()
        authorizationStatus = CLLocationManager.authorizationStatus()
    }
    
    func requestLocationPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        manager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        manager.stopUpdatingLocation()
        trackingTimer?.invalidate()
    }
    
    private func startPeriodicTracking() {
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            if let location = self?.userLocation {
                Task {
                    await self?.trackLocationIfNeeded(location)
                }
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        ActivityAPIClient.shared.logActivity(
            email: UserDefaults.standard.string(forKey: "moodgpt_username") ?? "anonymous_user",
            action: "locationAuthorizationChanged",
            details: ["newStatus": authorizationStatusString()]
        )
        
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            startLocationUpdates()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        if location.horizontalAccuracy < 100 {
            DispatchQueue.main.async {
                self.userLocation = location
                let coord = location.coordinate
                self.equatableLocation = EquatableCoordinate(coordinate: coord)
                self.isLocationFetched = true
                
                self.fetchCityAndState(for: coord)
                
                Task {
                    await self.trackLocationIfNeeded(location)
                }
                
                EnhancedTrackingService.shared.trackAPICall(
                    endpoint: "LocationManager",
                    method: "locationUpdate",
                    success: true
                )
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error.localizedDescription)")
        
        EnhancedTrackingService.shared.trackError(
            type: "LocationError",
            message: error.localizedDescription
        )
    }

    func fetchCityAndState(for coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                
                EnhancedTrackingService.shared.trackError(
                    type: "GeocodingError",
                    message: error.localizedDescription
                )
                return
            }
            
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self.cityName = placemark.locality ?? "Unknown"
                    self.stateName = placemark.administrativeArea ?? ""
                    
                    if let postalCode = placemark.postalCode, postalCode.count >= 3 {
                        self.areaCode = String(postalCode.prefix(3))
                    }
                    
                    ActivityAPIClient.shared.logActivity(
                        email: UserDefaults.standard.string(forKey: "moodgpt_username") ?? "anonymous_user",
                        action: "cityResolved",
                        details: [
                            "city": self.cityName,
                            "state": self.stateName,
                            "areaCode": self.areaCode
                        ]
                    )
                }
            }
        }
    }
    
    private func trackLocationIfNeeded(_ location: CLLocation) async {
        if let lastLocation = lastTrackedLocation {
            let distance = location.distance(from: lastLocation)
            if distance < trackingDistanceThreshold {
                return
            }
        }
        
        await apiService.trackLocation(location)
        lastTrackedLocation = location
        
        ActivityAPIClient.shared.logActivity(
            email: UserDefaults.standard.string(forKey: "moodgpt_username") ?? "anonymous_user",
            action: "locationTracked",
            details: [
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude,
                "accuracy": location.horizontalAccuracy,
                "altitude": location.altitude,
                "speed": location.speed,
                "timestamp": ISO8601DateFormatter().string(from: location.timestamp)
            ]
        )
    }
    
    func getRelevantAreaCode() -> String {
        return areaCode.isEmpty ? "602" : areaCode
    }
    
    // Fix: Use the LocationLogItem type from DataModels
    func fetchLocationHistory() async -> [LocationLogItem]? {
        do {
            return try await apiService.fetchLocationHistory()
        } catch {
            print("Failed to fetch location history: \(error)")
            
            EnhancedTrackingService.shared.trackError(
                type: "LocationHistoryError",
                message: error.localizedDescription
            )
            return nil
        }
    }
    
    private func authorizationStatusString() -> String {
        switch authorizationStatus {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedAlways: return "authorizedAlways"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        @unknown default: return "unknown"
        }
    }
}

struct EquatableCoordinate: Equatable {
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: EquatableCoordinate, rhs: EquatableCoordinate) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}
