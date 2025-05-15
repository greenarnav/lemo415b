import SwiftUI
import Combine
import CoreLocation
import UIKit

// MARK: - Enhanced Tracking Service
final class EnhancedTrackingService: ObservableObject {
    static let shared = EnhancedTrackingService()
    
    // Published properties for observing
    @Published var isTracking = true
    @Published var trackingStats: TrackingStats = TrackingStats()
    
    // User information
    private var username: String {
        return UserDefaults.standard.string(forKey: "moodgpt_username") ?? "anonymous_user"
    }
    
    // Session information
    private var sessionStartTime = Date()
    private var screenViewTimes: [String: Date] = [:]
    private var interactionCounts: [String: Int] = [:]
    
    // Battery monitoring
    private var batteryObserver: NSObjectProtocol?
    
    // App state observers
    private var appStateObservers: [NSObjectProtocol] = []
    
    // Periodic tracking timer
    private var trackingTimer: Timer?
    
    // Initialize
    private init() {
        setupBatteryMonitoring()
        setupAppStateObservers()
        startPeriodicTracking()
    }
    
    struct TrackingStats {
        var taps: Int = 0
        var swipes: Int = 0
        var scrolls: Int = 0
        var sessionDuration: TimeInterval = 0
        var screenViews: [String: Int] = [:]
        var apiCalls: Int = 0
        var errors: Int = 0
    }
    
    // MARK: - Setup Methods
    
    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        batteryObserver = NotificationCenter.default.addObserver(forName: UIDevice.batteryLevelDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.trackBatteryChange()
        }
    }
    
    private func setupAppStateObservers() {
        // App foreground
        let foregroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.trackAppForeground()
        }
        appStateObservers.append(foregroundObserver)
        
        // App background
        let backgroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.trackAppBackground()
        }
        appStateObservers.append(backgroundObserver)
        
        // Screenshot taken
        let screenshotObserver = NotificationCenter.default.addObserver(forName: UIApplication.userDidTakeScreenshotNotification, object: nil, queue: .main) { [weak self] _ in
            self?.trackScreenshot()
        }
        appStateObservers.append(screenshotObserver)
        
        // Memory warning
        let memoryObserver = NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main) { [weak self] _ in
            self?.trackMemoryWarning()
        }
        appStateObservers.append(memoryObserver)
    }
    
    private func startPeriodicTracking() {
        // Send stats every 5 minutes
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.sendPeriodicStats()
        }
    }
    
    // MARK: - Tracking Methods
    
    func trackScreenView(_ screenName: String) {
        guard isTracking else { return }
        
        // Record screen view time
        screenViewTimes[screenName] = Date()
        
        // Update stats
        if trackingStats.screenViews[screenName] != nil {
            trackingStats.screenViews[screenName]! += 1
        } else {
            trackingStats.screenViews[screenName] = 1
        }
        
        // Log activity
        ActivityAPIClient.shared.logActivity(
            email: username,
            action: "screenView",
            details: ["screenName": screenName]
        )
    }
    
    func trackTap(screenName: String, elementName: String? = nil, coordinates: CGPoint? = nil) {
        guard isTracking else { return }
        
        // Update stats
        trackingStats.taps += 1
        
        // Create details
        var details: [String: Any] = ["screenName": screenName]
        if let elementName = elementName {
            details["elementName"] = elementName
        }
        if let coordinates = coordinates {
            details["coordinates"] = ["x": coordinates.x, "y": coordinates.y]
        }
        
        // Log activity
        ActivityAPIClient.shared.logActivity(
            email: username,
            action: "tap",
            details: details
        )
    }
    
    func trackSwipe(screenName: String, direction: UISwipeGestureRecognizer.Direction, coordinates: CGPoint? = nil) {
        guard isTracking else { return }
        
        // Update stats
        trackingStats.swipes += 1
        
        // Create details
        var details: [String: Any] = [
            "screenName": screenName,
            "direction": directionString(direction)
        ]
        if let coordinates = coordinates {
            details["coordinates"] = ["x": coordinates.x, "y": coordinates.y]
        }
        
        // Log activity
        ActivityAPIClient.shared.logActivity(
            email: username,
            action: "swipe",
            details: details
        )
    }
    
    func trackScroll(screenName: String, offset: CGPoint) {
        guard isTracking else { return }
        
        // Update stats
        trackingStats.scrolls += 1
        
        // Only log every 5th scroll to avoid flooding
        if trackingStats.scrolls % 5 == 0 {
            // Log activity
            ActivityAPIClient.shared.logActivity(
                email: username,
                action: "scroll",
                details: [
                    "screenName": screenName,
                    "offset": ["x": offset.x, "y": offset.y]
                ]
            )
        }
    }
    
    func trackError(type: String, message: String, code: Int = 0) {
        guard isTracking else { return }
        
        // Update stats
        trackingStats.errors += 1
        
        // Log activity
        ActivityAPIClient.shared.logActivity(
            email: username,
            action: "error",
            details: [
                "errorType": type,
                "errorMessage": message,
                "errorCode": code
            ]
        )
    }
    
    func trackAPICall(endpoint: String, method: String, success: Bool, duration: TimeInterval? = nil) {
        guard isTracking else { return }
        
        // Update stats
        trackingStats.apiCalls += 1
        
        // Log activity
        ActivityAPIClient.shared.logActivity(
            email: username,
            action: "apiCall",
            details: [
                "endpoint": endpoint,
                "method": method,
                "success": success,
                "duration": duration ?? 0
            ]
        )
    }
    
    func trackButtonClick(screenName: String, buttonName: String) {
        guard isTracking else { return }
        
        // Increment tap count
        trackingStats.taps += 1
        
        // Track interaction with this button
        let key = "\(screenName)-\(buttonName)"
        if let count = interactionCounts[key] {
            interactionCounts[key] = count + 1
        } else {
            interactionCounts[key] = 1
        }
        
        // Log activity
        ActivityAPIClient.shared.logActivity(
            email: username,
            action: "buttonClick",
            details: [
                "screenName": screenName,
                "buttonName": buttonName,
                "interactionCount": interactionCounts[key] ?? 1
            ]
        )
    }
    
    func trackAppForeground() {
        guard isTracking else { return }
        
        // Reset session start time
        sessionStartTime = Date()
        
        // Get running applications info if available
        var runningApps: [String] = []
        #if targetEnvironment(simulator)
        // Simulator - can't access other apps
        #else
        // Real device - attempt to get some app info
        // Note: This is very limited on iOS due to sandboxing
        #endif
        
        // Get device state
        let deviceStats = collectDeviceStats()
        
        // Log activity
        ActivityAPIClient.shared.logActivity(
            email: username,
            action: "appForeground",
            details: [
                "deviceStats": deviceStats,
                "runningApps": runningApps
            ]
        )
    }
    
    func trackAppBackground() {
        guard isTracking else { return }
        
        // Calculate session duration
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        trackingStats.sessionDuration += sessionDuration
        
        // Log activity
        ActivityAPIClient.shared.logActivity(
            email: username,
            action: "appBackground",
            details: [
                "sessionDuration": sessionDuration,
                "totalTaps": trackingStats.taps,
                "totalSwipes": trackingStats.swipes,
                "totalScrolls": trackingStats.scrolls,
                "screenViews": trackingStats.screenViews
            ]
        )
    }
    
    private func trackBatteryChange() {
        guard isTracking else { return }
        
        // Log activity
        ActivityAPIClient.shared.logActivity(
            email: username,
            action: "batteryChange",
            details: [
                "level": UIDevice.current.batteryLevel,
                "state": UIDevice.current.batteryState.rawValue,
                "isLowPowerMode": ProcessInfo.processInfo.isLowPowerModeEnabled
            ]
        )
    }
    
    private func trackScreenshot() {
        guard isTracking else { return }
        
        // Log activity
        ActivityAPIClient.shared.logActivity(
            email: username,
            action: "screenshot",
            details: [:]
        )
    }
    
    private func trackMemoryWarning() {
        guard isTracking else { return }
        
        // Log activity
        ActivityAPIClient.shared.logActivity(
            email: username,
            action: "memoryWarning",
            details: [:]
        )
    }
    
    private func sendPeriodicStats() {
        guard isTracking else { return }
        
        // Collect all device stats
        let deviceStats = collectDeviceStats()
        
        // Add additional stats about session
        var sessionStats: [String: Any] = [
            "duration": Date().timeIntervalSince(sessionStartTime),
            "totalTaps": trackingStats.taps,
            "totalSwipes": trackingStats.swipes,
            "totalScrolls": trackingStats.scrolls,
            "screenViews": trackingStats.screenViews,
            "apiCalls": trackingStats.apiCalls,
            "errors": trackingStats.errors
        ]
        
        // Log activity with all collected stats
        ActivityAPIClient.shared.logActivity(
            email: username,
            action: "periodicStats",
            details: [
                "deviceStats": deviceStats,
                "sessionStats": sessionStats,
                "interactionCounts": interactionCounts
            ]
        )
    }
    
    // MARK: - Helper Methods
    
    private func collectDeviceStats() -> [String: Any] {
        // Basic device info
        var stats: [String: Any] = [
            "model": UIDevice.current.model,
            "systemName": UIDevice.current.systemName,
            "systemVersion": UIDevice.current.systemVersion,
            "batteryLevel": UIDevice.current.batteryLevel,
            "batteryState": UIDevice.current.batteryState.rawValue,
            "isLowPowerModeEnabled": ProcessInfo.processInfo.isLowPowerModeEnabled,
            "screenBrightness": UIScreen.main.brightness,
            "orientation": UIDevice.current.orientation.rawValue
        ]
        
        // Storage info
        let fileManager = FileManager.default
        if let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey])
                stats["storageAvailable"] = values.volumeAvailableCapacityForImportantUsage
                stats["storageTotal"] = values.volumeTotalCapacity
            } catch {
                print("Error getting storage info: \(error)")
            }
        }
        
        // Network info
        if let connectionType = NetworkMonitor.shared.connectionType {
            stats["networkType"] = String(describing: connectionType)
            stats["networkIsExpensive"] = NetworkMonitor.shared.isExpensive
            stats["networkIsConstrained"] = NetworkMonitor.shared.isConstrained
        }
        
        // Memory info
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kernResult = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kernResult == KERN_SUCCESS {
            stats["memoryUsed"] = info.resident_size
        }
        
        return stats
    }
    
    private func directionString(_ direction: UISwipeGestureRecognizer.Direction) -> String {
        switch direction {
        case .up: return "up"
        case .down: return "down"
        case .left: return "left"
        case .right: return "right"
        default: return "unknown"
        }
    }
}

// MARK: - SwiftUI View Extensions for Tracking
extension View {
    func trackScreenView(_ screenName: String) -> some View {
        return self.onAppear {
            EnhancedTrackingService.shared.trackScreenView(screenName)
        }
    }
    
    func trackTaps(screenName: String, elementName: String? = nil) -> some View {
        return self.simultaneousGesture(
            TapGesture().onEnded { _ in
                EnhancedTrackingService.shared.trackTap(screenName: screenName, elementName: elementName)
            }
        )
    }
    
    func trackButtonClick(screenName: String, buttonName: String) -> some View {
        return self.simultaneousGesture(
            TapGesture().onEnded { _ in
                EnhancedTrackingService.shared.trackButtonClick(screenName: screenName, buttonName: buttonName)
            }
        )
    }
    
    func trackSwipes(screenName: String) -> some View {
        return self
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        let verticalAmount = value.translation.height
                        
                        if abs(horizontalAmount) > abs(verticalAmount) {
                            // Horizontal swipe
                            let direction: UISwipeGestureRecognizer.Direction = horizontalAmount < 0 ? .left : .right
                            EnhancedTrackingService.shared.trackSwipe(screenName: screenName, direction: direction)
                        } else {
                            // Vertical swipe
                            let direction: UISwipeGestureRecognizer.Direction = verticalAmount < 0 ? .up : .down
                            EnhancedTrackingService.shared.trackSwipe(screenName: screenName, direction: direction)
                        }
                    }
            )
    }
    
    func trackScrollOffset(_ offset: CGPoint, screenName: String) -> some View {
        return self.onChange(of: offset) { oldValue, newValue in
            EnhancedTrackingService.shared.trackScroll(screenName: screenName, offset: newValue)
        }
    }
}
