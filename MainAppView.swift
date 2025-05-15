import SwiftUI

struct MainAppView: View {
    @State private var selectedTab: Int = 0
    @State private var showEmotionPicker: Bool = false
    @State private var selectedEmotion: String? = nil
    @State private var hasRequestedHealthPermission = false

    @EnvironmentObject var appState: AppState
    @StateObject private var emotionDatabase: EmotionDatabase = EmotionDatabase()
    @StateObject private var appDataManager = AppDataManager.shared
    @StateObject private var emotionSubmissionService = EmotionSubmissionService.shared
    @StateObject private var enhancedTracking = EnhancedTrackingService.shared
    @StateObject private var healthManager = HealthKitManager.shared

    // Available emotions
    let emotions = ["Happy", "Sad", "Calm", "Excited", "Anxious"]

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeScreen()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                MapScreen()
                    .tabItem {
                        Label("Map", systemImage: "map.fill")
                    }
                    .tag(1)

                EmptyView()
                    .tabItem {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                    .tag(2)

                ContactsScreen()
                    .tabItem {
                        Label("Contacts", systemImage: "person.2.fill")
                    }
                    .tag(3)

                SettingsScreen()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(4)
            }
            .accentColor(.white)
            .onAppear {
                // Customize tab bar appearance
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(white: 0, alpha: 0.9)
                
                // Configure unselected items
                appearance.stackedLayoutAppearance.normal.iconColor = UIColor.lightGray
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
                
                // Configure selected items
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
                
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
                
                // Start location services
                appState.startLocationServices()
                
                // Request HealthKit permission after a delay
                if !hasRequestedHealthPermission {
                    hasRequestedHealthPermission = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        healthManager.requestAuthorization()
                    }
                }
                
                // Track app launch
                enhancedTracking.trackScreenView("MainAppView")
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                // Track tab change
                enhancedTracking.trackButtonClick(
                    screenName: "MainAppView",
                    buttonName: "TabChange-\(tabName(for: newValue))"
                )
                
                if newValue == 2 {
                    showEmotionPicker = true
                    // Reset to previous tab
                    withAnimation(.none) {
                        selectedTab = oldValue
                    }
                }
            }

            // Emotion picker overlay
            if showEmotionPicker {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showEmotionPicker = false
                    }

                QuickEmotionPicker(
                    isShowing: $showEmotionPicker,
                    selectedEmotion: $selectedEmotion,
                    emotions: emotions,
                    onSubmit: submitEmotion
                )
                .transition(.scale)
                .animation(.spring(), value: showEmotionPicker)
            }
            
            // Notification overlay
            NotificationOverlay()
        }
        .environmentObject(emotionDatabase)
        .environmentObject(appDataManager)
        .environmentObject(emotionSubmissionService)
        .onAppear {
            NotificationIntegration.shared.setup()
        }
    }

    func submitEmotion() {
        guard let emotion = selectedEmotion else { return }
        let locationName = appState.getCurrentCityName()
        let location = appState.locationManager.userLocation
        
        // Save locally
        emotionDatabase.saveEmotion(
            emotion: emotion,
            location: locationName,
            timestamp: Date()
        )
        
        // Submit to remote database
        Task {
            await emotionSubmissionService.submitEmotion(
                emotion: emotion,
                location: locationName,
                latitude: location?.coordinate.latitude,
                longitude: location?.coordinate.longitude
            )
        }
        
        // Track emotion submission
        ActivityAPIClient.shared.logActivity(
            email: UserDefaults.standard.string(forKey: "moodgpt_username") ?? "anonymous_user",
            action: "emotionSubmitted",
            details: [
                "emotion": emotion,
                "location": locationName,
                "coordinates": [
                    "latitude": location?.coordinate.latitude ?? 0,
                    "longitude": location?.coordinate.longitude ?? 0
                ]
            ]
        )
        
        selectedEmotion = nil
        showEmotionPicker = false
    }
    
    // Helper function to get tab name for tracking
    private func tabName(for index: Int) -> String {
        switch index {
        case 0: return "Home"
        case 1: return "Map"
        case 2: return "Add"
        case 3: return "Contacts"
        case 4: return "Settings"
        default: return "Unknown"
        }
    }
}

// Quick emotion picker for tab bar
struct QuickEmotionPicker: View {
    @Binding var isShowing: Bool
    @Binding var selectedEmotion: String?
    let emotions: [String]
    let onSubmit: () -> Void
    
    // Consistent emoji mapping
    let emotionEmojis: [String: String] = [
        "Happy": "😊",
        "Sad": "😢",
        "Calm": "😌",
        "Excited": "🤩",
        "Anxious": "😰"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("How are you feeling?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                ForEach(emotions, id: \.self) { emotion in
                    Button(action: {
                        selectedEmotion = emotion
                        onSubmit()
                        
                        // Track emotion selection
                        EnhancedTrackingService.shared.trackButtonClick(
                            screenName: "EmotionPicker",
                            buttonName: "Selected-\(emotion)"
                        )
                    }) {
                        HStack(spacing: 16) {
                            Text(emotionEmojis[emotion] ?? "😐")
                                .font(.system(size: 36))
                            
                            Text(emotion)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if selectedEmotion == emotion {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(
                            selectedEmotion == emotion ?
                            Color.white.opacity(0.3) :
                            Color.white.opacity(0.1)
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            
            Button(action: {
                isShowing = false
                
                // Track cancellation
                EnhancedTrackingService.shared.trackButtonClick(
                    screenName: "EmotionPicker",
                    buttonName: "Cancel"
                )
            }) {
                Text("Cancel")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.6))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.black.opacity(0.9))
        )
        .frame(maxWidth: 350)
        .shadow(radius: 20)
        .onAppear {
            // Track emotion picker opened
            EnhancedTrackingService.shared.trackScreenView("EmotionPicker")
        }
    }
}
