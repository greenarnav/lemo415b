//
//  LocationLookup.swift
//  MoodGpt
//
//  Created by Test on 4/27/25.
//


//
//  LocationLookup.swift
//
import Foundation
import CoreLocation

struct LocationLookup {
    static let shared = LocationLookup()   // singleton
    
    private let table: [String: (name: String, coord: CLLocationCoordinate2D)]
    
    private init() {
        let url = Bundle.main.url(forResource: "locationDatabase", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let decoded = try! JSONDecoder().decode([LocationData].self, from: data)
        table = Dictionary(uniqueKeysWithValues: decoded.map {
            ($0.id,
             (name: $0.city,
              coord: CLLocationCoordinate2D(latitude: $0.latitude,
                                            longitude: $0.longitude)))
        })
    }
    
    func city(for areaCode: String) -> (String, CLLocationCoordinate2D)? {
        table[areaCode]
    }
}
