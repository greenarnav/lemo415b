import SwiftUI
import Contacts

@MainActor
final class ContactsViewModel: ObservableObject {
    struct Row: Identifiable {
        let id = UUID()
        let name: String
        let phone: String
        let city: String
        let emoji: String
        let mood: String
        let hasLocation: Bool
    }
    
    @Published var rows: [Row] = []
    @Published var loading = true
    @Published var authorizationStatus: CNAuthorizationStatus = .notDetermined
    @Published var permissionError: String? = nil
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    
    private let apiService = ApiIntegrationService.shared
    
    // Public
    func load() {
        loading = true
        permissionError = nil
        
        Task {
            // Check current authorization status first
            let store = CNContactStore()
            authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            
            if authorizationStatus == .notDetermined {
                await requestContactsAccess()
            }
            
            if authorizationStatus == .authorized {
                await refresh()
            }
            
            loading = false
        }
    }
    
    // Sync contacts to API
    func syncContactsToAPI() async {
        guard !rows.isEmpty else { return }
        
        await MainActor.run {
            self.isSyncing = true
        }
        
        await apiService.syncContacts(contacts: rows)
        
        await MainActor.run {
            self.isSyncing = false
            self.lastSyncDate = Date()
        }
    }
    
    // Request contacts permission
    private func requestContactsAccess() async {
        let store = CNContactStore()
        do {
            let granted = try await store.requestAccess(for: .contacts)
            authorizationStatus = granted ? .authorized : .denied
            if !granted {
                permissionError = "Contacts access was denied. Please grant permission in Settings."
            }
        } catch {
            authorizationStatus = .denied
            permissionError = "Error requesting contacts access: \(error.localizedDescription)"
            print("Error requesting contacts access: \(error)")
        }
    }
    
    // Private
    private func refresh() async {
        // Double-check authorization
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
            print("Contacts access not authorized")
            authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            return
        }
        
        // 1. Read ALL contacts
        let store = CNContactStore()
        
        // Include all necessary keys including the formatter key
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactPostalAddressesKey as CNKeyDescriptor,
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
        ]
        
        let req = CNContactFetchRequest(keysToFetch: keysToFetch)
        
        // Temporary holds all contacts
        var allContacts: [(name: String, phone: String, areaCode: String?)] = []
        
        do {
            try store.enumerateContacts(with: req) { contact, _ in
                // Use the formatter now that we have the proper key
                let fullName = CNContactFormatter.string(from: contact, style: .fullName) ??
                             "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                let displayName = fullName.isEmpty ? "No Name" : fullName
                let phone = contact.phoneNumbers.first?.value.stringValue ?? "No Phone"
                
                // Extract area code from phone number
                let areaCode = self.extractAreaCode(from: phone)
                
                allContacts.append((name: displayName, phone: phone, areaCode: areaCode))
            }
        } catch {
            print("Error fetching contacts: \(error)")
            permissionError = "Error fetching contacts: \(error.localizedDescription)"
            return
        }
        
        // 2. Process each contact and determine location/sentiment
        rows.removeAll()
        
        // Create a few sample contacts if none exist for testing
        if allContacts.isEmpty {
            // Add sample contacts for testing
            allContacts = [
                ("John Doe", "(212) 555-0101", "212"),
                ("Jane Smith", "(415) 555-0102", "415"),
                ("Test Contact", "555-0103", nil)
            ]
        }
        
        await withTaskGroup(of: Row?.self) { group in
            for contact in allContacts {
                group.addTask {
                    // Try to get location from area code
                    if let areaCode = contact.areaCode,
                       let location = AreaCodeLookup.city(for: areaCode) {
                        // Location found - get sentiment
                        let sentiment = try? await LocalSentimentService.shared.cityInfo(location.city)
                        return Row(
                            name: contact.name,
                            phone: contact.phone,
                            city: location.city,
                            emoji: sentiment?.emoji ?? "😐",
                            mood: sentiment?.label ?? "Unknown",
                            hasLocation: true
                        )
                    } else {
                        // Location not found - use question mark emoji
                        return Row(
                            name: contact.name,
                            phone: contact.phone,
                            city: "Location not found",
                            emoji: "❓",
                            mood: "Unknown",
                            hasLocation: false
                        )
                    }
                }
            }
            
            // Collect results
            for await result in group {
                if let row = result {
                    rows.append(row)
                }
            }
        }
        
        // Sort: First by location availability, then by name
        rows.sort { lhs, rhs in
            // Put contacts with locations first
            if lhs.hasLocation != rhs.hasLocation {
                return lhs.hasLocation
            }
            // Then sort by name
            return lhs.name < rhs.name
        }
        
        // Automatically sync to API after loading
        Task {
            await syncContactsToAPI()
            
            // Also update AppDataManager
            AppDataManager.shared.updateContactCities(from: rows)
        }
    }
    
    // Extract area code from phone number
    private func extractAreaCode(from phone: String) -> String? {
        // Remove all non-numeric characters
        let numericPhone = phone.filter { $0.isNumber }
        
        // US phone number patterns
        if numericPhone.count >= 10 {
            // Check if it starts with country code
            if numericPhone.hasPrefix("1") && numericPhone.count >= 11 {
                // +1 XXX XXX XXXX format
                let startIndex = numericPhone.index(numericPhone.startIndex, offsetBy: 1)
                let endIndex = numericPhone.index(startIndex, offsetBy: 3)
                return String(numericPhone[startIndex..<endIndex])
            } else if numericPhone.count >= 10 {
                // XXX XXX XXXX format
                let endIndex = numericPhone.index(numericPhone.startIndex, offsetBy: 3)
                return String(numericPhone[numericPhone.startIndex..<endIndex])
            }
        }
        
        // Try to extract area code from formatted numbers
        if let range = phone.range(of: #"\(?\d{3}\)?"#, options: .regularExpression) {
            let areaCodeString = String(phone[range])
            let areaCode = areaCodeString.filter { $0.isNumber }
            if areaCode.count == 3 {
                return areaCode
            }
        }
        
        return nil
    }
}

// MARK: - Local SentimentService Implementation
fileprivate struct LocalSentimentService {
    static let shared = LocalSentimentService()
    
    func cityInfo(_ city: String) async throws -> (emoji: String, label: String) {
        // Use our simplified emotion set
        let emotions = ["happy", "sad", "indifferent", "angry", "calm", "chaotic"]
        let emotion = emotions.randomElement() ?? "indifferent"
        
        return (emoji: getEmoji(for: emotion), label: emotion.capitalized)
    }
    
    // Helper function to get emoji for sentiment
    private func getEmoji(for sentiment: String) -> String {
        switch sentiment.lowercased() {
        case "happy":
            return "😊"
        case "sad":
            return "😢"
        case "indifferent":
            return "😐"
        case "angry":
            return "😡"
        case "calm":
            return "😌"
        case "chaotic":
            return "🤪"
        default:
            return "😐"
        }
    }
}
