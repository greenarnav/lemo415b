import UIKit
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static var isInitialLaunch = true
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(tokenString)")
        
        Task {
            await UserSpecificNotificationService.shared.registerDeviceToken(deviceToken)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        AppDelegate.isInitialLaunch = false
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        AppDelegate.isInitialLaunch = true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            handleNotificationTap(userInfo: userInfo)
            
        case UNNotificationDismissActionIdentifier:
            break
            
        default:
            handleCustomAction(actionIdentifier: actionIdentifier, userInfo: userInfo)
        }
        
        Task {
            await UserSpecificNotificationService.shared.markNotificationAsInteracted(
                response.notification.request.identifier,
                action: actionIdentifier
            )
        }
        
        completionHandler()
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        if let category = userInfo["category"] as? String {
            switch category {
            case "mood_check":
                NotificationCenter.default.post(name: .showMoodInput, object: nil)
                
            case "city_alert":
                if let cityName = userInfo["city"] as? String {
                    NotificationCenter.default.post(name: .showCityDetail, object: cityName)
                }
                
            case "recommendation":
                NotificationCenter.default.post(name: .showRecommendations, object: nil)
                
            default:
                break
            }
        }
    }
    
    private func handleCustomAction(actionIdentifier: String, userInfo: [AnyHashable: Any]) {
        switch actionIdentifier {
        case "view_details":
            if let itemId = userInfo["itemId"] as? String {
                NotificationCenter.default.post(name: .showItemDetail, object: itemId)
            }
            
        case "mark_read":
            break
            
        default:
            break
        }
    }
}

extension Notification.Name {
    static let showMoodInput = Notification.Name("showMoodInput")
    static let showCityDetail = Notification.Name("showCityDetail")
    static let showRecommendations = Notification.Name("showRecommendations")
    static let showItemDetail = Notification.Name("showItemDetail")
}
