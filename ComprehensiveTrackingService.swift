import Foundation
import SwiftUI
import CoreLocation
import UIKit

// MARK: - Device Statistics
struct DeviceStats: Codable {
    let batteryLevel: Float
    let batteryState: String
    let availableStorage: Int64
    let totalStorage: Int64
    let availableMemory: Int64
    let cpuUsage: Double
    let networkType: String
    let isJailbroken: Bool
    let screenBrightness: Float
    let isLowPowerMode: Bool
}

// MARK: - User Interaction Event
struct UserInteractionEvent: Codable {
    let id: UUID = UUID()
    let timestamp: Date
    let eventType: InteractionType
    let screenName: String
    let coordinates: CGPoint?
    let duration: TimeInterval?
    let metadata: [String: String]

    enum InteractionType: String, Codable {
        case tap, longPress, swipe, scroll, pinch, rotation
        case shake, screenshot, appBackground, appForeground, screenView, buttonTap
    }
}

// MARK: - Analytics Stubs (Renamed with CTS prefix)
enum CTSAnalyticsEventType {
    case custom
}

struct CTSAnalyticsEvent {
    let type: CTSAnalyticsEventType
    let screenName: String?
    let action: String
    let value: Double?
    let metadata: [String: String]

    init(type: CTSAnalyticsEventType, action: String, metadata: [String: String]) {
        self.type = type
        self.screenName = nil
        self.action = action
        self.value = nil
        self.metadata = metadata
    }

    init(type: CTSAnalyticsEventType, screenName: String, action: String, metadata: [String: String]) {
        self.type = type
        self.screenName = screenName
        self.action = action
        self.value = nil
        self.metadata = metadata
    }

    init(type: CTSAnalyticsEventType, action: String, value: Double, metadata: [String: String]) {
        self.type = type
        self.screenName = nil
        self.action = action
        self.value = value
        self.metadata = metadata
    }
}

class CTSAnalyticsService {
    static let shared = CTSAnalyticsService()
    private init() {}
    func track(event: CTSAnalyticsEvent) {
        // Replace with real analytics call
        print("[CTS Analytics] action=\(event.action), metadata=\(event.metadata)")
    }
}

// MARK: - Privacy Manager
@MainActor
class PrivacyManager: ObservableObject {
    static let shared = PrivacyManager()
    @Published var trackingEnabled = true
    @Published var batteryTrackingEnabled = true
    @Published var performanceTrackingEnabled = true
    @Published var behaviorTrackingEnabled = true
    @Published var locationTrackingEnabled = true

    private init() {
        loadSettings()
    }

    func updateTrackingPreferences() {
        saveSettings()
        Task { @MainActor in
            if !trackingEnabled {
                ComprehensiveTrackingService.shared.stopTracking()
            } else {
                ComprehensiveTrackingService.shared.startTracking()
            }
        }
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard
        trackingEnabled = defaults.bool(forKey: "privacy.trackingEnabled")
        batteryTrackingEnabled = defaults.bool(forKey: "privacy.batteryTracking")
        performanceTrackingEnabled = defaults.bool(forKey: "privacy.performanceTracking")
        behaviorTrackingEnabled = defaults.bool(forKey: "privacy.behaviorTracking")
        locationTrackingEnabled = defaults.bool(forKey: "privacy.locationTracking")
    }

    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(trackingEnabled, forKey: "privacy.trackingEnabled")
        defaults.set(batteryTrackingEnabled, forKey: "privacy.batteryTracking")
        defaults.set(performanceTrackingEnabled, forKey: "privacy.performanceTracking")
        defaults.set(behaviorTrackingEnabled, forKey: "privacy.behaviorTracking")
        defaults.set(locationTrackingEnabled, forKey: "privacy.locationTracking")
    }
}

// MARK: - Comprehensive Tracking Service
@MainActor
class ComprehensiveTrackingService: ObservableObject {
    static let shared = ComprehensiveTrackingService()

    @Published var currentBatteryLevel: Float = 0
    @Published var batteryState: UIDevice.BatteryState = .unknown
    @Published var deviceStats: DeviceStats?
    @Published var userInteractions: [UserInteractionEvent] = []
    @Published var isTracking = true

    private var sessionStartTime: Date = Date()
    private var screenViewTimes: [String: Date] = [:]
    private var scrollPositions: [String: CGFloat] = [:]
    private var heatmapData: [String: [CGPoint]] = [:]
    private var performanceTimer: Timer?
    private var displayLink: CADisplayLink?
    private var frameDrops: Int = 0
    private var totalFrames: Int = 0
    private let privacyManager = PrivacyManager.shared

    private init() {
        setupTracking()
    }

    private func setupTracking() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        setupNotificationObservers()
        startPerformanceMonitoring()
        startDeviceStatsMonitoring()
    }

    private func setupNotificationObservers() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(batteryLevelChanged), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        nc.addObserver(self, selector: #selector(batteryStateChanged), name: UIDevice.batteryStateDidChangeNotification, object: nil)
        nc.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        nc.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(userTookScreenshot), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        nc.addObserver(self, selector: #selector(memoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        nc.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    private func startDeviceStatsMonitoring() {
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor in self.updateDeviceStats() }
        }
        updateDeviceStats()
    }

    private func updateDeviceStats() {
        let device = UIDevice.current
        let (avail, total) = getStorageInfo()
        let availMem = getAvailableMemory()
        let cpu = getCPUUsage()
        let network = "WiFi"

        let stats = DeviceStats(
            batteryLevel: device.batteryLevel,
            batteryState: batteryStateString(device.batteryState),
            availableStorage: avail,
            totalStorage: total,
            availableMemory: availMem,
            cpuUsage: cpu,
            networkType: network,
            isJailbroken: isJailbroken(),
            screenBrightness: Float(UIScreen.main.brightness),
            isLowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled
        )

        deviceStats = stats
        sendDeviceStatsToAnalytics(stats)
    }

    private func startPerformanceMonitoring() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrameRate))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func updateFrameRate(displayLink: CADisplayLink) {
        totalFrames += 1
        if displayLink.timestamp - displayLink.targetTimestamp > 0.001 {
            frameDrops += 1
        }
        if totalFrames % 60 == 0 {
            let fps = Double(totalFrames - frameDrops) / Double(totalFrames) * 60
            reportFPS(fps)
            if totalFrames > 1000 {
                totalFrames = 0; frameDrops = 0
            }
        }
    }

    // MARK: - User Interaction
    func trackInteraction(
        type: UserInteractionEvent.InteractionType,
        screenName: String,
        coordinates: CGPoint? = nil,
        duration: TimeInterval? = nil,
        metadata: [String: String] = [:]
    ) {
        guard isTracking && privacyManager.behaviorTrackingEnabled else { return }
        let event = UserInteractionEvent(
            timestamp: Date(),
            eventType: type,
            screenName: screenName,
            coordinates: coordinates,
            duration: duration,
            metadata: metadata
        )
        userInteractions.append(event)
        if let coords = coordinates {
            heatmapData[screenName, default: []].append(coords)
        }
        if userInteractions.count > 1000 {
            userInteractions.removeFirst(userInteractions.count - 1000)
        }
        sendInteractionToAnalytics(event)
    }

    func trackScreenView(_ screenName: String) {
        screenViewTimes[screenName] = Date()
        trackInteraction(type: .screenView, screenName: screenName)
    }

    func trackScreenExit(_ screenName: String) {
        if let start = screenViewTimes[screenName] {
            let dur = Date().timeIntervalSince(start)
            trackInteraction(type: .screenView, screenName: screenName, duration: dur, metadata: ["exit": "true", "duration": String(dur)])
            screenViewTimes.removeValue(forKey: screenName)
        }
    }

    func trackScroll(screenName: String, position: CGFloat) {
        scrollPositions[screenName] = position
        trackInteraction(type: .scroll, screenName: screenName, metadata: ["position": "\(position)"])
    }

    // MARK: - Battery
    @objc private func batteryLevelChanged() {
        let level = UIDevice.current.batteryLevel
        if abs(level - currentBatteryLevel) > 0.05 {
            currentBatteryLevel = level
            trackBatteryChange()
        }
    }

    @objc private func batteryStateChanged() {
        batteryState = UIDevice.current.batteryState
        trackBatteryChange()
    }

    private func trackBatteryChange() {
        let meta = [
            "level": String(currentBatteryLevel),
            "state": batteryStateString(batteryState),
            "isLowPowerMode": String(ProcessInfo.processInfo.isLowPowerModeEnabled)
        ]
        trackInteraction(type: .appForeground, screenName: "System", metadata: meta)
    }

    // MARK: - App Lifecycle
    @objc private func appDidBecomeActive() {
        trackInteraction(type: .appForeground, screenName: "App")
        updateDeviceStats()
    }

    @objc private func appDidEnterBackground() {
        trackInteraction(type: .appBackground, screenName: "App")
        let dur = Date().timeIntervalSince(sessionStartTime)
        reportSessionDuration(dur)
    }

    @objc private func userTookScreenshot() {
        let meta = ["timestamp": ISO8601DateFormatter().string(from: Date())]
        trackInteraction(type: .screenshot, screenName: getCurrentScreenName(), metadata: meta)
    }

    @objc private func memoryWarning() {
        let availMem = getAvailableMemory()
        let meta = ["event": "memoryWarning", "availableMemory": String(availMem)]
        trackInteraction(type: .appForeground, screenName: "System", metadata: meta)
    }

    @objc private func orientationChanged() {
        let ori = UIDevice.current.orientation
        trackInteraction(type: .rotation, screenName: getCurrentScreenName(), metadata: ["orientation": orientationString(ori)])
    }

    // MARK: - Helpers
    private func getStorageInfo() -> (available: Int64, total: Int64) {
        do {
            let url = URL(fileURLWithPath: NSHomeDirectory())
            let vals = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey])
            return (Int64(vals.volumeAvailableCapacityForImportantUsage ?? 0), Int64(vals.volumeTotalCapacity ?? 0))
        } catch { return (0, 0) }
    }

    private func getAvailableMemory() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kr = withUnsafeMutablePointer(to: &info) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return kr == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }

    private func getCPUUsage() -> Double {
        let pi = ProcessInfo.processInfo
        return Double(pi.activeProcessorCount) / Double(pi.processorCount)
    }

    private func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        let paths = ["/Applications/Cydia.app", "/Library/MobileSubstrate/MobileSubstrate.dylib", "/bin/bash", "/usr/sbin/sshd", "/etc/apt", "/private/var/lib/apt/"]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
        #endif
    }

    private func getCurrentScreenName() -> String { return "Unknown" }

    private func batteryStateString(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .unknown: return "unknown"
        case .unplugged: return "unplugged"
        case .charging: return "charging"
        case .full: return "full"
        @unknown default: return "unknown"
        }
    }

    private func orientationString(_ orientation: UIDeviceOrientation) -> String {
        switch orientation {
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        case .faceUp: return "faceUp"
        case .faceDown: return "faceDown"
        default: return "unknown"
        }
    }

    // MARK: - Data Reporting
    private func sendDeviceStatsToAnalytics(_ stats: DeviceStats) {
        let meta = [
            "batteryLevel": String(stats.batteryLevel),
            "batteryState": stats.batteryState,
            "availableStorage": String(stats.availableStorage),
            "totalStorage": String(stats.totalStorage),
            "availableMemory": String(stats.availableMemory),
            "cpuUsage": String(stats.cpuUsage),
            "networkType": stats.networkType,
            "isJailbroken": String(stats.isJailbroken),
            "screenBrightness": String(stats.screenBrightness),
            "isLowPowerMode": String(stats.isLowPowerMode)
        ]
        CTSAnalyticsService.shared.track(event: CTSAnalyticsEvent(type: .custom, action: "deviceStats", metadata: meta))
    }

    private func sendInteractionToAnalytics(_ event: UserInteractionEvent) {
        var meta = event.metadata
        meta["eventType"] = event.eventType.rawValue
        if let c = event.coordinates {
            meta["x"] = "\(c.x)"
            meta["y"] = "\(c.y)"
        }
        if let d = event.duration {
            meta["duration"] = String(d)
        }
        CTSAnalyticsService.shared.track(event: CTSAnalyticsEvent(type: .custom, screenName: event.screenName, action: event.eventType.rawValue, metadata: meta))
    }

    private func reportFPS(_ fps: Double) {
        CTSAnalyticsService.shared.track(event: CTSAnalyticsEvent(type: .custom, action: "performance", value: fps, metadata: ["metric": "fps"]))
    }

    private func reportSessionDuration(_ duration: TimeInterval) {
        CTSAnalyticsService.shared.track(event: CTSAnalyticsEvent(type: .custom, action: "sessionEnd", value: duration, metadata: ["duration": String(duration)]))
    }

    // MARK: - Public Controls
    func startTracking() {
        isTracking = true
        updateDeviceStats()
    }

    func stopTracking() {
        isTracking = false
        performanceTimer?.invalidate()
        displayLink?.invalidate()
    }

    func exportTrackingData() -> Data? {
        let export = TrackingDataExport(
            deviceStats: deviceStats,
            interactions: userInteractions,
            heatmapData: heatmapData,
            sessionStartTime: sessionStartTime,
            exportTime: Date()
        )
        return try? JSONEncoder().encode(export)
    }
}

// MARK: - Export Data Model
struct TrackingDataExport: Codable {
    let deviceStats: DeviceStats?
    let interactions: [UserInteractionEvent]
    let heatmapData: [String: [CGPoint]]
    let sessionStartTime: Date
    let exportTime: Date
}

// MARK: - View Extensions
extension View {
    func trackDetailedInteraction() -> some View {
        self.onTapGesture { location in
            Task { ComprehensiveTrackingService.shared.trackInteraction(type: .tap, screenName: "CurrentScreen", coordinates: location) }
        }
    }

    func trackScrolling(screenName: String) -> some View {
        self.onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            if let offset = value {
                Task { ComprehensiveTrackingService.shared.trackScroll(screenName: screenName, position: offset) }
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = value ?? nextValue()
    }
}
