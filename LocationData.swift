import Foundation

struct LocationData: Codable, Identifiable {
    let id: String // Area code
    let city: String
    let state: String
    let country: String
    let timezone: String
    let latitude: Double
    let longitude: Double
    
    // Optional metadata
    let population: Int?
    let popularMoods: [String]?
}
