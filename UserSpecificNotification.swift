//
//  UserSpecificNotificationService.swift
//  MoodGpt
//
//  User‑specific push notification system
//

import Foundation
import UserNotifications
import UIKit
import Combine

// MARK: – Enums (renamed so they don’t collide)

/// Categories your user can subscribe to
enum AppNotificationCategory: String, CaseIterable, Codable, Hashable {
    case system
    case message
    case alert
    case promo
    case custom
}

/// Type of notification (sent vs. local vs. in‑app)
enum AppNotificationType: String, Codable {
    case push
    case local
    case inApp
}

// MARK: – Minimal API client (renamed)

/// A simple service to GET/POST JSON to your backend
class NotificationApiService {
    static let shared = NotificationApiService()
    private let baseURL = "https://api.moodgpt.com"
    
    private init() {}
    
    func fetchData(from endpoint: String) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        return data
    }
    
    func postData(to endpoint: String, body: Data) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}

// MARK: – Data models

struct UserNotificationProfile: Codable {
    let userId: String
    var deviceToken: String?
    var preferences: NotificationPreferences
    var quietHours: QuietHours?
    var subscribedCategories: Set<AppNotificationCategory>
    var notificationHistory: [NotificationHistoryItem]
    
    init(userId: String) {
        self.userId = userId
        self.preferences = NotificationPreferences()
        self.subscribedCategories = Set(AppNotificationCategory.allCases)
        self.notificationHistory = []
    }
}

struct NotificationPreferences: Codable {
    var enabled: Bool = true
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true
    var badgeEnabled: Bool = true
    var previewType: PreviewType = .always
    
    enum PreviewType: String, Codable {
        case always
        case whenUnlocked
        case never
    }
}

struct QuietHours: Codable {
    var isEnabled: Bool
    var startTime: Date
    var endTime: Date
    var daysOfWeek: Set<Int> // 1–7, where 1 is Sunday
}

struct NotificationHistoryItem: Codable {
    let id: UUID
    let notification: AppUserNotification
    let sentAt: Date
    var deliveredAt: Date?
    var readAt: Date?
    var interactedAt: Date?
    var action: String?
}

struct AppUserNotification: Codable {
    let id: String
    let userId: String
    let type: AppNotificationType
    let title: String
    let body: String
    let data: [String: String]?
    let scheduledAt: Date?
    let imageUrl: String?
    let category: AppNotificationCategory?
    let threadId: String?
    let actionButtons: [AppNotificationAction]?
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        type: AppNotificationType,
        title: String,
        body: String,
        data: [String: String]? = nil,
        scheduledAt: Date? = nil,
        imageUrl: String? = nil,
        category: AppNotificationCategory? = nil,
        threadId: String? = nil,
        actionButtons: [AppNotificationAction]? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.body = body
        self.data = data
        self.scheduledAt = scheduledAt
        self.imageUrl = imageUrl
        self.category = category
        self.threadId = threadId
        self.actionButtons = actionButtons
    }
}

struct AppNotificationAction: Codable {
    let identifier: String
    let title: String
    let options: Set<NotificationActionOption>
    let textInputPlaceholder: String?
    
    enum NotificationActionOption: String, Codable {
        case foreground
        case destructive
        case authenticationRequired
    }
}

// MARK: – WebSocket manager (unchanged)

class NotificationWebSocketManager: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private let baseURL = "wss://api.moodgpt.com/notifications/ws"
    
    @Published var isConnected = false
    var onNotificationReceived: ((AppUserNotification) -> Void)?
    
    func connect(userId: String, token: String) {
        guard let url = URL(string: "\(baseURL)?userId=\(userId)&token=\(token)") else { return }
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    self?.handleData(data)
                @unknown default:
                    break
                }
                self?.receiveMessage()
            case .failure:
                self?.isConnected = false
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard
            let data = text.data(using: .utf8),
            let n = try? JSONDecoder().decode(AppUserNotification.self, from: data)
        else { return }
        DispatchQueue.main.async { self.onNotificationReceived?(n) }
    }
    
    private func handleData(_ data: Data) {
        guard let n = try? JSONDecoder().decode(AppUserNotification.self, from: data) else { return }
        DispatchQueue.main.async { self.onNotificationReceived?(n) }
    }
}

// MARK: – Main notification service

@MainActor
class UserSpecificNotificationService: ObservableObject {
    static let shared = UserSpecificNotificationService()
    
    @Published var userProfile: UserNotificationProfile?
    @Published var pendingNotifications: [AppUserNotification] = []
    @Published var isConnected = false
    
    private let apiService = NotificationApiService.shared
    private let webSocketManager = NotificationWebSocketManager()
    private var reconnectTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupWebSocket()
    }
    
    private func setupWebSocket() {
        webSocketManager.onNotificationReceived = { [weak self] n in
            Task { await self?.handleIncomingNotification(n) }
        }
        webSocketManager.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] c in
                self?.isConnected = c
                if !c { self?.scheduleReconnect() }
            }
            .store(in: &cancellables)
    }
    
    func connect(userId: String, token: String) {
        Task {
            await loadUserProfile(userId: userId)
            webSocketManager.connect(userId: userId, token: token)
        }
    }
    
    func disconnect() {
        webSocketManager.disconnect()
        reconnectTimer?.invalidate()
    }
    
    private func scheduleReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard
                let p = self?.userProfile,
                let t = UserDefaults.standard.string(forKey: "authToken")
            else { return }
            self?.connect(userId: p.userId, token: t)
        }
    }
    
    private func loadUserProfile(userId: String) async {
        do {
            let data = try await apiService.fetchData(from: "/users/\(userId)/notification-profile")
            userProfile = try JSONDecoder().decode(UserNotificationProfile.self, from: data)
        } catch {
            userProfile = UserNotificationProfile(userId: userId)
        }
    }
    
    func updateUserProfile(_ profile: UserNotificationProfile) async {
        do {
            let body = try JSONEncoder().encode(profile)
            let data = try await apiService.postData(to: "/users/\(profile.userId)/notification-profile", body: body)
            userProfile = try JSONDecoder().decode(UserNotificationProfile.self, from: data)
        } catch {
            print("update profile failed:", error)
        }
    }
    
    func registerDeviceToken(_ token: Data) async {
        guard var p = userProfile else { return }
        p.deviceToken = token.map { String(format: "%02x", $0) }.joined()
        await updateUserProfile(p)
    }
    
    private func handleIncomingNotification(_ n: AppUserNotification) async {
        guard let p = userProfile, p.preferences.enabled else { return }
        if let q = p.quietHours, q.isEnabled, isCurrentlyQuietHours(q) {
            pendingNotifications.append(n)
            return
        }
        guard p.subscribedCategories.contains(n.category ?? .system) else { return }
        await scheduleLocalNotification(n)
        
        var np = p
        let item = NotificationHistoryItem(
            id: UUID(),
            notification: n,
            sentAt: Date(),
            deliveredAt: nil,
            readAt: nil,
            interactedAt: nil,
            action: nil
        )
        np.notificationHistory.append(item)
        if np.notificationHistory.count > 100 {
            np.notificationHistory = Array(np.notificationHistory.suffix(100))
        }
        await updateUserProfile(np)
    }
    
    private func isCurrentlyQuietHours(_ q: QuietHours) -> Bool {
        let now = Date()
        let cal = Calendar.current
        let dow = cal.component(.weekday, from: now)
        guard q.daysOfWeek.contains(dow) else { return false }
        
        let nowComp = cal.dateComponents([.hour, .minute], from: now)
        let nowM = (nowComp.hour! * 60) + nowComp.minute!
        let sC   = cal.dateComponents([.hour, .minute], from: q.startTime)
        let eC   = cal.dateComponents([.hour, .minute], from: q.endTime)
        let sM   = (sC.hour! * 60) + sC.minute!
        let eM   = (eC.hour! * 60) + eC.minute!
        
        if sM > eM { return nowM >= sM || nowM <= eM }
        else       { return nowM >= sM && nowM <= eM }
    }
    
    private func scheduleLocalNotification(_ n: AppUserNotification) async {
        let content = UNMutableNotificationContent()
        content.title = n.title
        content.body  = n.body
        
        if let p = userProfile {
            content.sound = p.preferences.soundEnabled ? .default : nil
            content.badge = p.preferences.badgeEnabled
                ? NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
                : nil
        }
        
        content.categoryIdentifier = n.category?.rawValue ?? ""
        content.threadIdentifier   = n.threadId ?? ""
        if let d = n.data { content.userInfo = d }
        
        if let acts = n.actionButtons {
            let catId = "category_\(n.id)"
            let uActs = acts.map { act in
                UNNotificationAction(
                    identifier: act.identifier,
                    title: act.title,
                    options: UNNotificationActionOptions(act.options)
                )
            }
            let category = UNNotificationCategory(
                identifier: catId,
                actions: uActs,
                intentIdentifiers: [],
                options: []
            )
            UNUserNotificationCenter.current().setNotificationCategories([category])
            content.categoryIdentifier = catId
        }
        
        let interval = n.scheduledAt?.timeIntervalSinceNow ?? 0.1
        let trigger  = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request  = UNNotificationRequest(identifier: n.id, content: content, trigger: trigger)
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("scheduling local failed:", error)
        }
    }
    
    func sendNotificationToUser(notification: AppUserNotification) async {
        do {
            let body = try JSONEncoder().encode(notification)
            _ = try await apiService.postData(to: "/notifications/send", body: body)
        } catch {
            print("sendNotification failed:", error)
        }
    }
    
    func fetchPendingNotifications() async {
        guard let p = userProfile else { return }
        do {
            let data = try await apiService.fetchData(from: "/users/\(p.userId)/notifications/pending")
            let arr  = try JSONDecoder().decode([AppUserNotification].self, from: data)
            pendingNotifications = arr
            for n in arr {
                if !isCurrentlyQuietHours(p.quietHours ?? QuietHours(isEnabled: false, startTime: Date(), endTime: Date(), daysOfWeek: [])) {
                    await scheduleLocalNotification(n)
                }
            }
        } catch {
            print("fetchPending failed:", error)
        }
    }
    
    func updateNotificationPreferences(_ prefs: NotificationPreferences) async {
        guard var p = userProfile else { return }
        p.preferences = prefs
        await updateUserProfile(p)
    }
    
    func updateQuietHours(_ q: QuietHours?) async {
        guard var p = userProfile else { return }
        p.quietHours = q
        await updateUserProfile(p)
    }
    
    func updateCategorySubscriptions(_ cats: Set<AppNotificationCategory>) async {
        guard var p = userProfile else { return }
        p.subscribedCategories = cats
        await updateUserProfile(p)
    }
    
    func markNotificationAsRead(_ id: String) async {
        guard
            var p = userProfile,
            let idx = p.notificationHistory.firstIndex(where: { $0.notification.id == id })
        else { return }
        p.notificationHistory[idx].readAt = Date()
        await updateUserProfile(p)
    }
    
    func markNotificationAsInteracted(_ id: String, action: String) async {
        guard
            var p = userProfile,
            let idx = p.notificationHistory.firstIndex(where: { $0.notification.id == id })
        else { return }
        p.notificationHistory[idx].interactedAt = Date()
        p.notificationHistory[idx].action = action
        await updateUserProfile(p)
    }
}

// MARK: – Extension (no stray comma!)

extension UNNotificationActionOptions {
    init(_ options: Set<AppNotificationAction.NotificationActionOption>) {
        var result: UNNotificationActionOptions = []
        if options.contains(.foreground)           { result.insert(.foreground) }
        if options.contains(.destructive)          { result.insert(.destructive) }
        if options.contains(.authenticationRequired) { result.insert(.authenticationRequired) }
        self = result
    }
}
