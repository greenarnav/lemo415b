import SwiftUI
import Combine
import CoreLocation

class AppState: ObservableObject {
    // ✅ Singleton shared instance
    static let shared = AppState()
    
    // ✅ Prevent multiple instantiations
    private init() {}

    @Published var locationManager = LocationManager()

    func startLocationServices() {
        locationManager.requestLocationPermission()
        locationManager.startLocationUpdates()
    }

    func getCurrentCityName() -> String {
        return locationManager.cityName.isEmpty ? "Locating..." : locationManager.cityName
    }

    func getCurrentStateName() -> String {
        return locationManager.stateName.isEmpty ? "" : locationManager.stateName
    }

    func getFormattedLocation() -> String {
        let city = getCurrentCityName()
        let state = getCurrentStateName()

        if city != "Locating..." && !state.isEmpty {
            return "\(city), \(state)"
        } else if city != "Locating..." {
            return city
        } else {
            return "Locating..."
        }
    }

    func getLocationAreaCode() -> String {
        return locationManager.getRelevantAreaCode()
    }
}
