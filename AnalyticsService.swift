//
//  AnalyticsService.swift
//  MoodGpt
//
//  Core analytics service for tracking user interactions
//

import Foundation
import SwiftUI

// MARK: - Analytics Event Type
enum AnalyticsEventType: String, CaseIterable, Codable {
    case screenView = "Screen View"
    case buttonTap = "Button Tap"
    case apiCall = "API Call"
    case error = "Error"
    case touch = "Touch"
    case custom = "Custom"
    case featureUsed = "Feature Used"
    case gesture = "Gesture"
    case sessionEnd = "Session End"
}

// MARK: - Analytics Event
struct AnalyticsEvent: Identifiable, Codable {
    let id = UUID()
    let type: AnalyticsEventType
    let timestamp: Date
    let screenName: String?
    let action: String?
    let label: String?
    let value: Double?
    let metadata: [String: String]?
    
    init(type: AnalyticsEventType,
         screenName: String? = nil,
         action: String? = nil,
         label: String? = nil,
         value: Double? = nil,
         metadata: [String: String]? = nil) {
        self.type = type
        self.timestamp = Date()
        self.screenName = screenName
        self.action = action
        self.label = label
        self.value = value
        self.metadata = metadata
    }
}

// MARK: - Touch Interaction
struct TouchInteraction: Codable {
    let location: CodablePoint
    let screenName: String
    let timestamp: Date
    let elementName: String?
    
    init(location: CGPoint, screenName: String, timestamp: Date, elementName: String?) {
        self.location = CodablePoint(x: location.x, y: location.y)
        self.screenName = screenName
        self.timestamp = timestamp
        self.elementName = elementName
    }
}

// MARK: - CodablePoint
struct CodablePoint: Codable {
    let x: CGFloat
    let y: CGFloat
    
    init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
    
    init(from cgPoint: CGPoint) {
        self.x = cgPoint.x
        self.y = cgPoint.y
    }
    
    var cgPoint: CGPoint {
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Analytics Summary
struct AnalyticsSummary {
    let totalEvents: Int
    let totalTouches: Int
    let sessionDuration: TimeInterval
    let screenViews: Int
    let buttonTaps: Int
    let apiCalls: Int
    let errors: Int
    let mostViewedScreen: String
    let apiSuccessRate: Double
}

// MARK: - Heatmap Data
struct HeatmapData {
    let location: CGPoint
    let intensity: Double
}

// MARK: - Analytics Service
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    @Published var isTracking = true
    @Published var events: [AnalyticsEvent] = []
    @Published var touchInteractions: [TouchInteraction] = []
    
    let userId: String
    let currentSessionId: String
    private let sessionStartTime: Date
    
    private init() {
        self.userId = UserDefaults.standard.string(forKey: "analytics_user_id") ?? UUID().uuidString
        self.currentSessionId = UUID().uuidString
        self.sessionStartTime = Date()
        
        // Save user ID for future sessions
        UserDefaults.standard.set(userId, forKey: "analytics_user_id")
        
        // Load saved events
        loadEvents()
    }
    
    // MARK: - Public Methods
    
    func trackScreenView(_ screenName: String) {
        guard isTracking else { return }
        
        let event = AnalyticsEvent(
            type: .screenView,
            screenName: screenName,
            action: "View"
        )
        
        addEvent(event)
    }
    
    func trackButtonTap(_ buttonName: String) {
        guard isTracking else { return }
        
        let event = AnalyticsEvent(
            type: .buttonTap,
            action: "Tap",
            label: buttonName
        )
        
        addEvent(event)
    }
    
    func trackTouch(at location: CGPoint, on screenName: String, element: String? = nil) {
        guard isTracking else { return }
        
        let interaction = TouchInteraction(
            location: location,
            screenName: screenName,
            timestamp: Date(),
            elementName: element
        )
        
        touchInteractions.append(interaction)
        
        let event = AnalyticsEvent(
            type: .touch,
            screenName: screenName,
            action: "Touch",
            label: element,
            metadata: [
                "x": String(format: "%.1f", location.x),
                "y": String(format: "%.1f", location.y)
            ]
        )
        
        addEvent(event)
    }
    
    func track(event: AnalyticsEvent) {
        guard isTracking else { return }
        addEvent(event)
    }
    
    func trackAPICall(endpoint: String, method: String, success: Bool, duration: TimeInterval? = nil) {
        guard isTracking else { return }
        
        let event = AnalyticsEvent(
            type: .apiCall,
            action: method,
            label: endpoint,
            value: duration,
            metadata: [
                "success": String(success),
                "endpoint": endpoint
            ]
        )
        
        addEvent(event)
    }
    
    func trackError(type: String, message: String, code: String? = nil) {
        guard isTracking else { return }
        
        var metadata: [String: String] = [
            "error_type": type,
            "message": message
        ]
        
        if let code = code {
            metadata["code"] = code
        }
        
        let event = AnalyticsEvent(
            type: .error,
            action: type,
            label: message,
            metadata: metadata
        )
        
        addEvent(event)
    }
    
    // MARK: - Analytics Summary
    
    func getAnalyticsSummary() -> AnalyticsSummary {
        let totalEvents = events.count
        let totalTouches = touchInteractions.count
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        
        let screenViews = events.filter { $0.type == .screenView }.count
        let buttonTaps = events.filter { $0.type == .buttonTap }.count
        let apiCalls = events.filter { $0.type == .apiCall }.count
        let errors = events.filter { $0.type == .error }.count
        
        // Find most viewed screen
        let screenCounts = events
            .filter { $0.type == .screenView }
            .compactMap { $0.screenName }
            .reduce(into: [:]) { counts, screen in
                counts[screen, default: 0] += 1
            }
        
        let mostViewedScreen = screenCounts.max(by: { $0.value < $1.value })?.key ?? "Unknown"
        
        // Calculate API success rate
        let apiEvents = events.filter { $0.type == .apiCall }
        let successfulAPIs = apiEvents.filter { $0.metadata?["success"] == "true" }.count
        let apiSuccessRate = apiEvents.isEmpty ? 1.0 : Double(successfulAPIs) / Double(apiEvents.count)
        
        return AnalyticsSummary(
            totalEvents: totalEvents,
            totalTouches: totalTouches,
            sessionDuration: sessionDuration,
            screenViews: screenViews,
            buttonTaps: buttonTaps,
            apiCalls: apiCalls,
            errors: errors,
            mostViewedScreen: mostViewedScreen,
            apiSuccessRate: apiSuccessRate
        )
    }
    
    // MARK: - Heatmap Data
    
    func generateHeatmapData(for screenName: String) -> [HeatmapData] {
        let screenTouches = touchInteractions.filter { $0.screenName == screenName }
        
        // Group touches by proximity
        var heatmapData: [HeatmapData] = []
        let gridSize: CGFloat = 50
        
        var touchGrid: [String: Int] = [:]
        
        for touch in screenTouches {
            let gridX = Int(touch.location.x / gridSize)
            let gridY = Int(touch.location.y / gridSize)
            let key = "\(gridX),\(gridY)"
            touchGrid[key, default: 0] += 1
        }
        
        for (key, count) in touchGrid {
            let components = key.split(separator: ",")
            guard components.count == 2,
                  let gridX = Int(components[0]),
                  let gridY = Int(components[1]) else { continue }
            
            let x = CGFloat(gridX) * gridSize + gridSize / 2
            let y = CGFloat(gridY) * gridSize + gridSize / 2
            let intensity = min(Double(count) / 10.0, 1.0)
            
            heatmapData.append(HeatmapData(
                location: CGPoint(x: x, y: y),
                intensity: intensity
            ))
        }
        
        return heatmapData
    }
    
    // MARK: - Private Methods
    
    private func addEvent(_ event: AnalyticsEvent) {
        events.append(event)
        saveEvents()
        
        // Limit stored events
        if events.count > 1000 {
            events.removeFirst(events.count - 1000)
        }
    }
    
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: "analytics_events")
        }
    }
    
    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: "analytics_events"),
           let decoded = try? JSONDecoder().decode([AnalyticsEvent].self, from: data) {
            events = decoded
        }
    }
}

// MARK: - View Extension for Easy Tracking
extension View {
    func trackAnalyticsScreen(_ screenName: String) -> some View {
        self.onAppear {
            AnalyticsService.shared.trackScreenView(screenName)
        }
    }
    
    func trackAnalyticsButtonTap(_ buttonName: String) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                AnalyticsService.shared.trackButtonTap(buttonName)
            }
        )
    }
}
