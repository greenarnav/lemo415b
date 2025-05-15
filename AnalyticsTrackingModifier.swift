//
//  AnalyticsTrackingModifier.swift
//  MoodGpt
//
//  Easy-to-use analytics wrapper for SwiftUI views
//

import SwiftUI

// MARK: - Analytics View Modifier
struct AnalyticsTrackingModifier: ViewModifier {
    let screenName: String
    @State private var hasTrackedView = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasTrackedView {
                    AnalyticsService.shared.trackScreenView(screenName)
                    hasTrackedView = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Re-track when app becomes active
                AnalyticsService.shared.trackScreenView(screenName)
            }
    }
}

// MARK: - Touch Tracking Modifier
struct TouchTrackingModifier: ViewModifier {
    let screenName: String
    let elementName: String?
    
    func body(content: Content) -> some View {
        content
            .onTapGesture { location in
                AnalyticsService.shared.trackTouch(
                    at: location,
                    on: screenName,
                    element: elementName
                )
            }
    }
}

// MARK: - Button Tracking Modifier
struct ButtonTrackingModifier: ViewModifier {
    let buttonName: String
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    AnalyticsService.shared.trackButtonTap(buttonName)
                }
            )
    }
}

// MARK: - View Extensions
extension View {
    // Track screen views using modifier
    func trackScreenWithModifier(_ screenName: String) -> some View {
        modifier(AnalyticsTrackingModifier(screenName: screenName))
    }
    
    // Track touches
    func trackTouch(screen: String, element: String? = nil) -> some View {
        modifier(TouchTrackingModifier(screenName: screen, elementName: element))
    }
    
    // Track button taps using modifier
    func trackButtonWithModifier(_ buttonName: String) -> some View {
        modifier(ButtonTrackingModifier(buttonName: buttonName))
    }
    
    // Track any analytics event
    func trackEvent(type: AnalyticsEventType, action: String? = nil, label: String? = nil, value: Double? = nil) -> some View {
        self.onTapGesture {
            AnalyticsService.shared.track(event: AnalyticsEvent(
                type: type,
                action: action,
                label: label,
                value: value
            ))
        }
    }
}

// MARK: - Analytics Debug View
struct AnalyticsDebugView: View {
    @ObservedObject private var analytics = AnalyticsService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Summary Tab
                SummaryTab()
                    .tabItem {
                        Label("Summary", systemImage: "chart.bar")
                    }
                    .tag(0)
                
                // Events Tab
                EventsTab()
                    .tabItem {
                        Label("Events", systemImage: "list.bullet")
                    }
                    .tag(1)
                
                // Heatmap Tab
                HeatmapTab()
                    .tabItem {
                        Label("Heatmap", systemImage: "map")
                    }
                    .tag(2)
                
                // Settings Tab
                SettingsTab()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(3)
            }
            .navigationTitle("Analytics Debug")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Summary Tab
struct SummaryTab: View {
    @ObservedObject private var analytics = AnalyticsService.shared
    
    var summary: AnalyticsSummary {
        analytics.getAnalyticsSummary()
    }
    
    var body: some View {
        List {
            Section("Overview") {
                SummaryRow(title: "Total Events", value: "\(summary.totalEvents)")
                SummaryRow(title: "Total Touches", value: "\(summary.totalTouches)")
                SummaryRow(title: "Session Duration", value: formatDuration(summary.sessionDuration))
            }
            
            Section("Event Types") {
                SummaryRow(title: "Screen Views", value: "\(summary.screenViews)")
                SummaryRow(title: "Button Taps", value: "\(summary.buttonTaps)")
                SummaryRow(title: "API Calls", value: "\(summary.apiCalls)")
                SummaryRow(title: "Errors", value: "\(summary.errors)")
            }
            
            Section("Insights") {
                SummaryRow(title: "Most Viewed Screen", value: summary.mostViewedScreen)
                SummaryRow(title: "API Success Rate", value: String(format: "%.1f%%", summary.apiSuccessRate * 100))
            }
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: abs(duration)) ?? "0s"
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// Events Tab
struct EventsTab: View {
    @ObservedObject private var analytics = AnalyticsService.shared
    @State private var filteredEventType: AnalyticsEventType?
    
    var filteredEvents: [AnalyticsEvent] {
        if let type = filteredEventType {
            return analytics.events.filter { $0.type == type }
        }
        return analytics.events
    }
    
    var body: some View {
        VStack {
            // Filter picker
            Picker("Event Type", selection: $filteredEventType) {
                Text("All").tag(nil as AnalyticsEventType?)
                ForEach(AnalyticsEventType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type as AnalyticsEventType?)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Events list
            List(filteredEvents.reversed()) { event in
                EventRow(event: event)
            }
        }
    }
}

struct EventRow: View {
    let event: AnalyticsEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(event.type.rawValue)
                    .font(.headline)
                    .foregroundColor(colorForEventType(event.type))
                
                Spacer()
                
                Text(event.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let screen = event.screenName {
                Text("Screen: \(screen)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let action = event.action {
                Text("Action: \(action)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let label = event.label {
                Text("Label: \(label)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    func colorForEventType(_ type: AnalyticsEventType) -> Color {
        switch type {
        case .screenView: return .blue
        case .buttonTap: return .green
        case .apiCall: return .orange
        case .error: return .red
        default: return .primary
        }
    }
}

// Heatmap Tab
struct HeatmapTab: View {
    @ObservedObject private var analytics = AnalyticsService.shared
    @State private var selectedScreen = "HomeScreen"
    
    let availableScreens = ["HomeScreen", "MapScreen", "ContactsScreen", "SettingsScreen"]
    
    var body: some View {
        VStack {
            // Screen picker
            Picker("Screen", selection: $selectedScreen) {
                ForEach(availableScreens, id: \.self) { screen in
                    Text(screen).tag(screen)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Heatmap visualization
            GeometryReader { geometry in
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                    
                    // Heatmap points
                    ForEach(Array(analytics.generateHeatmapData(for: selectedScreen).enumerated()), id: \.offset) { index, data in
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.red.opacity(data.intensity),
                                        Color.red.opacity(data.intensity * 0.5),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 1,
                                    endRadius: 30
                                )
                            )
                            .frame(width: 60, height: 60)
                            .position(data.location)
                    }
                    
                    // Screen name overlay
                    VStack {
                        Text(selectedScreen)
                            .font(.headline)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                        Spacer()
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
}

// Settings Tab
struct SettingsTab: View {
    @ObservedObject private var analytics = AnalyticsService.shared
    
    var body: some View {
        List {
            Section("Tracking") {
                Toggle("Enable Analytics", isOn: $analytics.isTracking)
            }
            
            Section("Data") {
                Button("Export Analytics Data") {
                    exportAnalyticsData()
                }
                
                Button("Clear Analytics Data") {
                    clearAnalyticsData()
                }
                .foregroundColor(.red)
            }
            
            Section("Debug") {
                HStack {
                    Text("User ID")
                    Spacer()
                    Text(analytics.userId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Session ID")
                    Spacer()
                    Text(analytics.currentSessionId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    func exportAnalyticsData() {
        // Export implementation
        print("Exporting analytics data...")
    }
    
    func clearAnalyticsData() {
        analytics.events.removeAll()
        analytics.touchInteractions.removeAll()
        UserDefaults.standard.removeObject(forKey: "analytics_events")
        UserDefaults.standard.removeObject(forKey: "touch_interactions")
    }
}
