// Fixed Extensions.swift - Implementing toString for ScenePhase

import SwiftUI
import Foundation
import UIKit
import CoreLocation

// MARK: - ScenePhase Extensions
extension ScenePhase {
    // Add toString() function implementation
    func toString() -> String {
        switch self {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        @unknown default:
            return "unknown"
        }
    }
}

// MARK: - UIApplication Extensions
extension UIApplication {
    // Get the top-most view controller for presenting alerts, etc.
    static var topViewController: UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first { $0.isKeyWindow }
        
        guard let rootViewController = window?.rootViewController else {
            return nil
        }
        
        var topController = rootViewController
        
        while let newController = topController.presentedViewController {
            topController = newController
        }
        
        return topController
    }
    
    // Get a list of running applications - Note: this only works in limited ways due to iOS sandboxing
    static var runningApplications: [String] {
        var apps: [String] = []
        
        // Due to iOS sandboxing, we can only detect a few things:
        
        // 1. Check if Photos is being used
        let photoAuth = PHPhotoLibrary.authorizationStatus()
        if photoAuth == .authorized || photoAuth == .limited {
            apps.append("Photos")
        }
        
        // 2. Check if Camera is being used
        let cameraAuth = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraAuth == .authorized {
            apps.append("Camera")
        }
        
        // 3. Check if Microphone is being used
        let micAuth = AVAudioSession.sharedInstance().recordPermission
        if micAuth == .granted {
            apps.append("Microphone")
        }
        
        // 4. Check if Location is being used
        let locAuth = CLLocationManager.authorizationStatus()
        if locAuth == .authorizedWhenInUse || locAuth == .authorizedAlways {
            apps.append("Location")
        }
        
        return apps
    }
}

// MARK: - String Extensions
extension String {
    // Check if string is a valid email
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    // Get a consistent hash code for a string (helpful for deterministic features)
    var stableHashCode: Int {
        var h = 0
        for char in self {
            h = h &* 31 &+ Int(char.asciiValue ?? 0)
        }
        return h
    }
}

// MARK: - View Extensions for UI Help
extension View {
    // Add rounded corners to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    // Add shadow with specific parameters
    func standardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    // Conditional modifier application
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    // Show/hide based on condition
    @ViewBuilder func isHidden(_ hidden: Bool, remove: Bool = false) -> some View {
        if hidden {
            if !remove {
                self.hidden()
            }
        } else {
            self
        }
    }
}

// Helper shape for rounded corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Date Extensions
extension Date {
    // Format date to string with specific format
    func toString(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    // Get time ago string (e.g. "2 hours ago")
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    // Get the start of the day
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    // Get the end of the day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
}

// MARK: - Swift Standard Library Extensions
extension Array where Element: Hashable {
    // Get unique elements while preserving order
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

extension Dictionary {
    // Merge with another dictionary, with values from the second dictionary taking precedence
    mutating func merge(with other: [Key: Value]) {
        for (key, value) in other {
            self[key] = value
        }
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    // Check if this is the first launch ever
    static var isFirstLaunch: Bool {
        let hasBeenLaunchedBefore = UserDefaults.standard.bool(forKey: "hasBeenLaunchedBefore")
        if !hasBeenLaunchedBefore {
            UserDefaults.standard.set(true, forKey: "hasBeenLaunchedBefore")
            return true
        }
        return false
    }
    
    // Get/set username with default fallback - using a different method name to avoid conflicts
    func getUsername() -> String {
        if let saved = string(forKey: "moodgpt_username"), !saved.isEmpty {
            return saved
        }
        let generated = "user_\(UUID().uuidString.prefix(8))"
        set(generated, forKey: "moodgpt_username")
        return generated
    }
    
    func setUsername(_ newValue: String) {
        set(newValue, forKey: "moodgpt_username")
    }
    
    // Clear all app data (for debugging/testing)
    static func clearAll() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Core Location Extensions
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// For Photo and AVFoundation imports
import Photos
import AVFoundation
