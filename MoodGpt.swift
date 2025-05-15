import SwiftUI

@main  // Added this attribute to fix the linker error
struct MoodGpt: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var remoteNotificationService = RemoteNotificationService.shared
    @StateObject private var enhancedTracking = EnhancedTrackingService.shared
    
    @Environment(\.scenePhase) var scenePhase
    
    @AppStorage("hasBeenLaunchedBefore") private var hasBeenLaunchedBefore = false
    @State private var shouldShowLanding = false
    @State private var showUsernamePrompt = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if shouldShowLanding && !hasBeenLaunchedBefore {
                    // Show landing screen only on fresh launch
                    LandingScreen()
                } else if showUsernamePrompt {
                    // Show username prompt if needed
                    UsernamePromptView(isPresented: $showUsernamePrompt)
                } else {
                    // Show the main app
                    MainAppView()
                        .environmentObject(AppState.shared)
                }
            }
            .environmentObject(AppState.shared)
            .environmentObject(notificationManager)
            .environmentObject(remoteNotificationService)
            .environmentObject(enhancedTracking)
            .onAppear {
                requestNotificationPermissions()
                checkIfFreshLaunch()
                checkIfUsernameExists()
                UNUserNotificationCenter.current().delegate = appDelegate
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }
    
    private func checkIfFreshLaunch() {
        shouldShowLanding = !hasBeenLaunchedBefore
        if !hasBeenLaunchedBefore {
            hasBeenLaunchedBefore = true
        }
    }
    
    private func checkIfUsernameExists() {
        let username = UserDefaults.standard.string(forKey: "moodgpt_username")
        if username == nil || username?.isEmpty == true {
            showUsernamePrompt = true
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
                DispatchQueue.main.async {
                    notificationManager.isAuthorized = true
                }
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            print("App became active")
            UIApplication.shared.applicationIconBadgeNumber = 0
            notificationManager.updatePendingNotifications()
            remoteNotificationService.startPollingForNotifications()
            
            // Track app becoming active
            let username = UserDefaults.standard.string(forKey: "moodgpt_username") ?? "anonymous_user"
            ActivityAPIClient.shared.logActivity(
                email: username,
                action: "appBecameActive",
                details: [
                    "previousState": oldPhase.toString()
                ]
            )
            
        case .inactive:
            print("App became inactive")
            
        case .background:
            print("App went to background")
            remoteNotificationService.stopPollingForNotifications()
            
            // Track app going to background
            let username = UserDefaults.standard.string(forKey: "moodgpt_username") ?? "anonymous_user"
            ActivityAPIClient.shared.logActivity(
                email: username,
                action: "appEnteredBackground",
                details: [:]
            )
            
        @unknown default:
            print("Unknown scene phase")
        }
    }
}
