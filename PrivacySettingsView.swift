import SwiftUI
import UIKit

// MARK: - Privacy Settings View
struct PrivacySettingsView: View {
    @ObservedObject private var privacy = PrivacyManager.shared
    @ObservedObject private var tracking = ComprehensiveTrackingService.shared

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tracking Preferences")) {
                    Toggle("Enable Analytics", isOn: $privacy.trackingEnabled)
                        .onChange(of: privacy.trackingEnabled) { _ in
                            privacy.updateTrackingPreferences()
                        }

                    Toggle("Track Battery Usage", isOn: $privacy.batteryTrackingEnabled)
                        .disabled(!privacy.trackingEnabled)

                    Toggle("Track Performance", isOn: $privacy.performanceTrackingEnabled)
                        .disabled(!privacy.trackingEnabled)

                    Toggle("Track Behavior", isOn: $privacy.behaviorTrackingEnabled)
                        .disabled(!privacy.trackingEnabled)

                    Toggle("Track Location", isOn: $privacy.locationTrackingEnabled)
                        .disabled(!privacy.trackingEnabled)
                }

                Section(header: Text("Data Management")) {
                    HStack {
                        Text("Tracked Interactions")
                        Spacer()
                        Text("\(tracking.userInteractions.count)")
                            .foregroundColor(.secondary)
                    }

                    Button("Export My Data") {
                        exportUserData()
                    }

                    Button("Clear Tracking Data") {
                        clearTrackingData()
                    }
                    .foregroundColor(.red)
                }

                Section(header: Text("Debug")) {
                    NavigationLink("View Analytics", destination: AnalyticsDebugView())
                    NavigationLink("View Device Stats", destination: DeviceStatsView())
                }
            }
            .navigationTitle("Privacy Settings")
        }
    }

    // MARK: - Actions
    private func exportUserData() {
        guard let data = tracking.exportTrackingData() else { return }
        let fileName = "MoodGPT_UserData_\(Date().timeIntervalSince1970).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: url)
            let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.present(activity, animated: true)
            }
        } catch {
            print("Failed to export data: \(error)")
        }
    }

    private func clearTrackingData() {
        tracking.userInteractions.removeAll()
        // Additional cleanup if needed
    }
}

// MARK: - Analytics Debug View


// MARK: - Device Stats View
struct DeviceStatsView: View {
    @ObservedObject private var tracking = ComprehensiveTrackingService.shared
    var body: some View {
        List {
            if let stats = tracking.deviceStats {
                Section(header: Text("Battery")) {
                    HStack { Text("Level"); Spacer(); Text("\(Int(stats.batteryLevel * 100))%") }
                    HStack { Text("State"); Spacer(); Text(stats.batteryState.capitalized) }
                    HStack { Text("Low Power Mode"); Spacer(); Text(stats.isLowPowerMode ? "On" : "Off") }
                }
                Section(header: Text("Storage")) {
                    HStack { Text("Available"); Spacer(); Text(ByteCountFormatter.string(fromByteCount: stats.availableStorage, countStyle: .binary)) }
                    HStack { Text("Total"); Spacer(); Text(ByteCountFormatter.string(fromByteCount: stats.totalStorage, countStyle: .binary)) }
                }
                Section(header: Text("Performance")) {
                    HStack { Text("CPU Usage"); Spacer(); Text("\(Int(stats.cpuUsage * 100))%") }
                    HStack { Text("Memory"); Spacer(); Text(ByteCountFormatter.string(fromByteCount: stats.availableMemory, countStyle: .memory)) }
                }
                Section(header: Text("Device")) {
                    HStack { Text("Network"); Spacer(); Text(stats.networkType) }
                    HStack { Text("Brightness"); Spacer(); Text("\(Int(stats.screenBrightness * 100))%") }
                    HStack { Text("Jailbroken"); Spacer(); Text(stats.isJailbroken ? "Yes" : "No") }
                }
            } else {
                Text("Gathering device stats...")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Device Stats")
    }
}

// MARK: - Preview
struct PrivacySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacySettingsView()
    }
}
