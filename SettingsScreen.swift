import SwiftUI

struct SettingsScreen: View {
    // Use EnvironmentObject with explicit type annotations
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var emotionDatabase: EmotionDatabase
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var showClearDataAlert: Bool = false
    @State private var selectedTab: String = "general"
    @State private var username: String = UserDefaults.standard.username
    @State private var isEditingUsername: Bool = false
    
    @StateObject private var apiService = ApiIntegrationService.shared
    @StateObject private var remoteNotifications = RemoteNotificationService.shared
    @StateObject private var contactsViewModel = ContactsViewModel()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.6),
                    Color.purple.opacity(0.5),
                    Color.white.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "gear")
                    Text("Settings").font(.title2)
                    Spacer()
                }
                .foregroundColor(.white)
                .padding()
                
                // Tab selector
                HStack(spacing: 0) {
                    tabButton(title: "General", tab: "general")
                    tabButton(title: "Notifications", tab: "notifications")
                    tabButton(title: "API Sync", tab: "sync")
                    tabButton(title: "About", tab: "about")
                }
                .padding(.horizontal)
                
                // Content based on selected tab
                ScrollView {
                    if selectedTab == "general" {
                        generalSettingsContent
                    } else if selectedTab == "notifications" {
                        NotificationSettingsView()
                    } else if selectedTab == "sync" {
                        apiSyncContent
                    } else if selectedTab == "about" {
                        aboutContent
                    }
                }
            }
        }
    }
    
    // Tab button helper
    private func tabButton(title: String, tab: String) -> some View {
        Button(action: {
            withAnimation {
                selectedTab = tab
            }
        }) {
            Text(title)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.7))
                .background(
                    selectedTab == tab ?
                    Color.white.opacity(0.2) :
                    Color.clear
                )
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Tab Content Views
    
    // General Settings Content
    private var generalSettingsContent: some View {
        VStack(spacing: 20) {
            // User Profile Section
            settingsSection(title: "User Profile") {
                HStack {
                    Image(systemName: "person.circle")
                        .foregroundColor(.white)
                    
                    if isEditingUsername {
                        TextField("Username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                saveUsername()
                            }
                        
                        Button("Save") {
                            saveUsername()
                        }
                        .foregroundColor(.green)
                        
                        Button("Cancel") {
                            username = UserDefaults.standard.username
                            isEditingUsername = false
                        }
                        .foregroundColor(.red)
                    } else {
                        Text(username)
                            .foregroundColor(.white)
                        Spacer()
                        Button("Edit") {
                            isEditingUsername = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(10)
            }
            
            // App info section
            settingsSection(title: "App Info") {
                settingsRow(icon: "info.circle", title: "Version", detail: "1.0.0")
                settingsRow(icon: "envelope.fill", title: "Contact", detail: "support@moodgpt.com")
            }
            
            // Location Section
            settingsSection(title: "Location") {
                settingsRow(icon: "location.fill", title: "Current Location", detail: appState.getFormattedLocation())
                
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                        Text("Location Settings")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                }
            }
            
            // Data Management Section
            settingsSection(title: "Data Management") {
                Button(action: {
                    showClearDataAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Clear Emotion Data")
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                }
                .alert(isPresented: $showClearDataAlert) {
                    Alert(
                        title: Text("Clear Emotion Data"),
                        message: Text("This will delete all your saved emotion records. This action cannot be undone."),
                        primaryButton: .destructive(Text("Delete")) {
                            emotionDatabase.userEmotions = []
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
        .padding()
    }
    
    // API Sync Content
    private var apiSyncContent: some View {
        VStack(spacing: 20) {
            // Sync Status
            settingsSection(title: "Sync Status") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.white)
                        Text("Contacts Sync")
                            .foregroundColor(.white)
                        Spacer()
                        if apiService.isUploading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            if let lastSync = apiService.lastSync {
                                Text(lastSync, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            } else {
                                Text("Never synced")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    
                    Button(action: {
                        Task {
                            contactsViewModel.load()
                            await contactsViewModel.syncContactsToAPI()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Sync Contacts Now")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(apiService.isUploading)
                    
                    if let error = apiService.syncError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(10)
            }
            
            // Location Tracking
            settingsSection(title: "Location Tracking") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "location.circle")
                            .foregroundColor(.white)
                        Text("Location History")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    Button(action: {
                        Task {
                            if let logs = await appState.locationManager.fetchLocationHistory() {
                                print("Location history: \(logs.count) entries")
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("View Location History")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Text("Location is automatically tracked when you move")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(10)
            }
            
            // Remote Notifications
            settingsSection(title: "Remote Notifications") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundColor(.white)
                        Text("Server Notifications")
                            .foregroundColor(.white)
                        Spacer()
                        if remoteNotifications.isPolling {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Active")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    // Polling status
                    HStack {
                        Text("Status:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(remoteNotifications.getPollingStatus())
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    // Last processed ID
                    HStack {
                        Text("Last processed ID:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(remoteNotifications.getLastProcessedId())")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    // Notification count
                    HStack {
                        Text("Notifications received:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(remoteNotifications.notificationHistory.count)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    if let lastNotification = remoteNotifications.lastNotification {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Notification:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Text(lastNotification.body)
                                .font(.caption)
                                .foregroundColor(.white)
                                .lineLimit(2)
                            Text(lastNotification.timestamp, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Recent notifications
                    if !remoteNotifications.notificationHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent Notifications:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(remoteNotifications.notificationHistory.prefix(5)) { notification in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(notification.body)
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                    .lineLimit(2)
                                                Text(notification.timestamp, style: .relative)
                                                    .font(.caption2)
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                            Spacer()
                                        }
                                        .padding(8)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(6)
                                    }
                                }
                            }
                            .frame(maxHeight: 150)
                        }
                    }
                    
                    // Test notification button
                    Button(action: {
                        Task {
                            await remoteNotifications.sendTestNotification()
                        }
                    }) {
                        HStack {
                            Image(systemName: "bell.fill")
                            Text("Send Test Notification")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    // Clear history button
                    if !remoteNotifications.notificationHistory.isEmpty {
                        Button(action: {
                            remoteNotifications.clearNotificationHistory()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear Notification History")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(10)
            }
        }
        .padding()
        .onAppear {
            remoteNotifications.startPollingForNotifications()
        }
        .onDisappear {
            remoteNotifications.stopPollingForNotifications()
        }
    }
    
    // About Content
    private var aboutContent: some View {
        VStack(spacing: 20) {
            // App info
            VStack(spacing: 16) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 64))
                    .foregroundColor(.white)
                
                Text("MoodGPT")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            
            // About section
            VStack(alignment: .leading, spacing: 16) {
                Text("About MoodGPT")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("MoodGPT helps you track your emotions and see how others around you are feeling. Explore the emotional climate of your city and connect with the collective sentiment of people around you.")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Color.white.opacity(0.15))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Contact Info
            VStack(alignment: .leading, spacing: 16) {
                Text("Contact Us")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Button(action: {
                    if let url = URL(string: "mailto:sheetal@city-mood.ai") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.white)
                        Text("sheetal@city-mood.ai")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                }
                
                Button(action: {
                    if let url = URL(string: "https://moodgpt.com") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.white)
                        Text("Visit our website")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                }
            }
            .padding()
            .background(Color.white.opacity(0.15))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func saveUsername() {
        UserDefaults.standard.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        isEditingUsername = false
    }
    
    // Helper view builders with explicit function signatures
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            content()
        }
    }
    
    private func settingsRow(icon: String, title: String, detail: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
            Text(title)
                .foregroundColor(.white)
            Spacer()
            Text(detail)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(10)
    }
}

// Add preview provider
struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen()
            .environmentObject(AppState.shared)
            .environmentObject(EmotionDatabase())
            .environmentObject(NotificationManager.shared)
    }
}
