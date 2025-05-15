//
//  ApiIntegrationService.swift
//  MoodGpt
//
//  Handles integration with external APIs for contacts and location tracking
//

import Foundation
import Contacts
import CoreLocation
import UserNotifications

// MARK: - API Models
struct ContactUpload: Codable {
    let username: String
    let contacts: [ContactItem]
}

struct ContactItem: Codable {
    let name: String
    let phone: String
}

struct ContactsResponse: Codable {
    let username: String
    let contacts: [ContactItem]
}

struct LocationTrackData: Codable {
    let username: String
    let latitude: Double
    let longitude: Double
}

struct LocationTrackResponse: Codable {
    let message: String
}

struct LocationLogItem: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: String
    let username: String
}

// MARK: - API Service
class ApiIntegrationService: ObservableObject {
    static let shared = ApiIntegrationService()
    
    private let contactsAPIBase = "https://contactsapi.vercel.app"
    private let locationAPIBase = "https://location-tracking-zeta.vercel.app"
    
    @Published var isUploading = false
    @Published var lastSync: Date?
    @Published var syncError: String?
    
    // Current user - can be set in app settings
    private var currentUsername: String {
        UserDefaults.standard.string(forKey: "moodgpt_username") ?? "user_\(UUID().uuidString.prefix(8))"
    }
    
    // MARK: - Contacts API Methods
    
    func syncContacts(contacts: [ContactsViewModel.Row]) async {
        await MainActor.run {
            self.isUploading = true
            self.syncError = nil
        }
        
        // Convert to API format
        let contactItems = contacts.map { contact in
            ContactItem(name: contact.name, phone: contact.phone)
        }
        
        let upload = ContactUpload(username: currentUsername, contacts: contactItems)
        
        do {
            // Prepare request
            let url = URL(string: "\(contactsAPIBase)/add_contact")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(upload)
            
            // Send request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                await MainActor.run {
                    self.lastSync = Date()
                    print("Contacts synced successfully: \(contactItems.count) contacts")
                }
            } else {
                throw URLError(.badServerResponse)
            }
            
        } catch {
            await MainActor.run {
                self.syncError = "Failed to sync contacts: \(error.localizedDescription)"
                print("Contact sync error: \(error)")
            }
        }
        
        await MainActor.run {
            self.isUploading = false
        }
    }
    
    func fetchContacts() async throws -> [ContactItem] {
        let url = URL(string: "\(contactsAPIBase)/search/\(currentUsername)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ContactsResponse.self, from: data)
        return response.contacts
    }
    
    // MARK: - Location API Methods
    
    func trackLocation(_ location: CLLocation) async {
        let trackData = LocationTrackData(
            username: currentUsername,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        do {
            // Prepare request
            let url = URL(string: "\(locationAPIBase)/track")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(trackData)
            
            // Send request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let trackResponse = try JSONDecoder().decode(LocationTrackResponse.self, from: data)
                print("Location tracked: \(trackResponse.message)")
            }
            
        } catch {
            print("Location tracking error: \(error)")
        }
    }
    
    func fetchLocationHistory() async throws -> [LocationLogItem] {
        let url = URL(string: "\(locationAPIBase)/track/\(currentUsername)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let logs = try JSONDecoder().decode([LocationLogItem].self, from: data)
        return logs
    }
    
    // MARK: - Notification Support
    
    func sendNotificationToUser(title: String, body: String, username: String? = nil) async {
        // This method can be called from your server or admin panel to send notifications
        // The actual implementation would depend on your notification backend
        
        let targetUser = username ?? currentUsername
        
        // You could implement this by polling an endpoint or using websockets
        // For now, we'll show how to create a local notification as an example
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "remote-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Notification scheduled for user: \(targetUser)")
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
}

// MARK: - User Settings Extension
extension UserDefaults {
    var username: String {
        get {
            if let saved = string(forKey: "moodgpt_username"), !saved.isEmpty {
                return saved
            }
            let generated = "user_\(UUID().uuidString.prefix(8))"
            self.username = generated
            return generated
        }
        set {
            set(newValue, forKey: "moodgpt_username")
        }
    }
}
