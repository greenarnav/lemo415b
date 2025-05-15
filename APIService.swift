//
//  APIService.swift
//  MoodGpt
//
//  Comprehensive API service with fallback cases and retry logic
//

import Foundation
import Network
import Combine
import CoreLocation
import UIKit
import SwiftUI

// MARK: - API Configuration
struct APIConfiguration {
    static let baseURL = "https://api.moodgpt.com"
    static let fallbackURL = "https://fallback.moodgpt.com"
    static let cacheDuration: TimeInterval = 300 // 5 minutes
    static let timeout: TimeInterval = 30
    static let maxRetries = 3
    static let retryDelay: TimeInterval = 2.0
}

// MARK: - API Error Types
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case serverError(statusCode: Int, message: String?)
    case timeout
    case offline
    case rateLimited(retryAfter: TimeInterval?)
    case unauthorized
    case invalidResponse
    case cacheMiss
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error \(code): \(message ?? "Unknown error")"
        case .timeout:
            return "Request timed out"
        case .offline:
            return "No internet connection"
        case .rateLimited(let retryAfter):
            if let retry = retryAfter {
                return "Rate limited. Retry after \(Int(retry)) seconds"
            }
            return "Rate limited"
        case .unauthorized:
            return "Unauthorized access"
        case .invalidResponse:
            return "Invalid response format"
        case .cacheMiss:
            return "No cached data available"
        }
    }
}

// MARK: - Request Configuration
struct APIRequest: Codable {
    let endpoint: String
    let method: HTTPMethod
    let parameters: [String: String]?
    let headers: [String: String]?
    let body: Data?
    let requiresAuth: Bool
    let cachePolicy: CachePolicy
    let retryPolicy: RetryPolicy
    
    enum HTTPMethod: String, Codable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case patch = "PATCH"
    }
    
    enum CachePolicy: String, Codable {
        case none
        case returnCacheElseLoad
        case returnCacheAndLoad
        case cacheOnly
    }
    
    struct RetryPolicy: Codable {
        let maxAttempts: Int
        let delay: TimeInterval
        let backoffMultiplier: Double
        
        static let `default` = RetryPolicy(
            maxAttempts: 3,
            delay: 2.0,
            backoffMultiplier: 2.0
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case endpoint, method, requiresAuth
    }
    
    init(endpoint: String, method: HTTPMethod, parameters: [String: String]? = nil, headers: [String: String]? = nil, body: Data? = nil, requiresAuth: Bool = true, cachePolicy: CachePolicy = .returnCacheElseLoad, retryPolicy: RetryPolicy = .default) {
        self.endpoint = endpoint
        self.method = method
        self.parameters = parameters
        self.headers = headers
        self.body = body
        self.requiresAuth = requiresAuth
        self.cachePolicy = cachePolicy
        self.retryPolicy = retryPolicy
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        endpoint = try container.decode(String.self, forKey: .endpoint)
        let methodString = try container.decode(String.self, forKey: .method)
        method = HTTPMethod(rawValue: methodString) ?? .get
        requiresAuth = try container.decode(Bool.self, forKey: .requiresAuth)
        
        // Default values for other properties
        parameters = nil
        headers = nil
        body = nil
        cachePolicy = .none
        retryPolicy = .default
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(endpoint, forKey: .endpoint)
        try container.encode(method.rawValue, forKey: .method)
        try container.encode(requiresAuth, forKey: .requiresAuth)
    }
}

// MARK: - API Cache Manager
actor APICacheManager {
    static let shared = APICacheManager()
    
    private var memoryCache: [String: CachedResponse] = [:]
    private var diskCache: [String: CachedResponse] = [:]
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    struct CachedResponse: Codable {
        let data: Data
        let headers: [String: String]
        let timestamp: Date
        let expiresAt: Date?
    }
    
    private init() {
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentDirectory.appendingPathComponent("APICache")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Load disk cache
        Task {
            await loadDiskCache()
        }
    }
    
    func cache(data: Data, for key: String, headers: [String: String], ttl: TimeInterval?) {
        let expiresAt = ttl != nil ? Date().addingTimeInterval(ttl!) : nil
        let cachedResponse = CachedResponse(
            data: data,
            headers: headers,
            timestamp: Date(),
            expiresAt: expiresAt
        )
        
        memoryCache[key] = cachedResponse
        saveToDisk(response: cachedResponse, key: key)
        
        Task {
            await cleanupExpiredCache()
        }
    }
    
    func getCachedData(for key: String) -> CachedResponse? {
        // Check memory cache first
        if let cached = memoryCache[key] {
            if let expiresAt = cached.expiresAt, expiresAt < Date() {
                memoryCache.removeValue(forKey: key)
                return nil
            }
            return cached
        }
        
        // Check disk cache
        if let cached = diskCache[key] {
            if let expiresAt = cached.expiresAt, expiresAt < Date() {
                diskCache.removeValue(forKey: key)
                removeDiskCache(for: key)
                return nil
            }
            // Move to memory cache
            memoryCache[key] = cached
            return cached
        }
        
        return nil
    }
    
    func invalidateCache(for key: String) {
        memoryCache.removeValue(forKey: key)
        diskCache.removeValue(forKey: key)
        removeDiskCache(for: key)
    }
    
    func clearAllCache() {
        memoryCache.removeAll()
        diskCache.removeAll()
        
        // Clear disk cache
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    private func saveToDisk(response: CachedResponse, key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? key)
        
        let encoder = PropertyListEncoder()
        if let data = try? encoder.encode(response) {
            try? data.write(to: fileURL)
        }
    }
    
    private func loadDiskCache() {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else { return }
        
        let decoder = PropertyListDecoder()
        for file in files {
            if let data = try? Data(contentsOf: file),
               let cached = try? decoder.decode(CachedResponse.self, from: data) {
                let key = file.lastPathComponent.removingPercentEncoding ?? file.lastPathComponent
                diskCache[key] = cached
            }
        }
    }
    
    private func removeDiskCache(for key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? key)
        try? fileManager.removeItem(at: fileURL)
    }
    
    private func cleanupExpiredCache() {
        // Clean memory cache
        let now = Date()
        memoryCache = memoryCache.filter { _, cached in
            if let expiresAt = cached.expiresAt {
                return expiresAt > now
            }
            return true
        }
        
        // Clean disk cache
        diskCache = diskCache.filter { key, cached in
            if let expiresAt = cached.expiresAt, expiresAt <= now {
                removeDiskCache(for: key)
                return false
            }
            return true
        }
    }
}

// MARK: - API Service
@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    
    @Published var isLoading = false
    @Published var error: APIError?
    @Published var networkStatus = NetworkMonitor.shared
    
    private let session: URLSession
    private let cache = APICacheManager.shared
    private var activeTasks: [String: URLSessionTask] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // Auth token management
    private var authToken: String = ""
    
    // Rate limiting
    private var requestQueue: [APIRequest] = []
    private var requestTimestamps: [Date] = []
    private let rateLimitWindow: TimeInterval = 60.0
    private let rateLimitMaxRequests = 60
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfiguration.timeout
        configuration.timeoutIntervalForResource = APIConfiguration.timeout * 2
        configuration.waitsForConnectivity = true
        configuration.allowsCellularAccess = true
        configuration.allowsConstrainedNetworkAccess = true
        configuration.allowsExpensiveNetworkAccess = true
        
        self.session = URLSession(configuration: configuration)
        
        // Monitor network changes
        networkStatus.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.processQueuedRequests()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Auth Token Management
    
    func setAuthToken(_ token: String) {
        authToken = token
    }
    
    // MARK: - Public API
    
    func request<T: Codable>(
        _ type: T.Type,
        endpoint: String,
        method: APIRequest.HTTPMethod = .get,
        parameters: [String: String]? = nil,
        headers: [String: String]? = nil,
        body: Data? = nil,
        requiresAuth: Bool = true,
        cachePolicy: APIRequest.CachePolicy = .returnCacheElseLoad,
        retryPolicy: APIRequest.RetryPolicy = .default
    ) async throws -> T {
        
        let request = APIRequest(
            endpoint: endpoint,
            method: method,
            parameters: parameters,
            headers: headers,
            body: body,
            requiresAuth: requiresAuth,
            cachePolicy: cachePolicy,
            retryPolicy: retryPolicy
        )
        
        // Check cache first if applicable
        if cachePolicy != .none && method == .get {
            let cacheKey = createCacheKey(for: request)
            
            if cachePolicy == .returnCacheAndLoad || cachePolicy == .returnCacheElseLoad {
                if let cached = await cache.getCachedData(for: cacheKey) {
                    if let decoded = try? JSONDecoder().decode(APIResponseWrapper<T>.self, from: cached.data),
                       let data = decoded.data {
                        // If returnCacheAndLoad, also fetch fresh data
                        if cachePolicy == .returnCacheAndLoad {
                            Task {
                                _ = try? await performRequest(request, responseType: T.self)
                            }
                        }
                        return data
                    }
                }
            }
            
            if cachePolicy == .cacheOnly {
                throw APIError.cacheMiss
            }
        }
        
        // Check network connectivity
        guard networkStatus.isConnected else {
            // Queue request for later if offline
            queueRequest(request)
            throw APIError.offline
        }
        
        // Rate limiting check
        if isRateLimited() {
            queueRequest(request)
            throw APIError.rateLimited(retryAfter: calculateRetryAfter())
        }
        
        // Perform request with retry logic
        return try await performRequestWithRetry(request, responseType: T.self)
    }
    
    // MARK: - Private Methods
    
    private func performRequestWithRetry<T: Codable>(_ request: APIRequest, responseType: T.Type) async throws -> T {
        var lastError: Error?
        var retryCount = 0
        let maxRetries = request.retryPolicy.maxAttempts
        var delay = request.retryPolicy.delay
        
        while retryCount < maxRetries {
            do {
                return try await performRequest(request, responseType: responseType)
            } catch let error as APIError {
                lastError = error
                
                // Don't retry certain errors
                switch error {
                case .unauthorized, .invalidURL, .decodingError:
                    throw error
                case .rateLimited(let retryAfter):
                    delay = retryAfter ?? delay
                case .serverError(let code, _):
                    // Don't retry client errors (4xx)
                    if code >= 400 && code < 500 {
                        throw error
                    }
                default:
                    break
                }
                
                // Exponential backoff
                retryCount += 1
                if retryCount < maxRetries {
                    print("Retry \(retryCount)/\(maxRetries) after \(delay)s for \(request.endpoint)")
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    delay *= request.retryPolicy.backoffMultiplier
                }
            } catch {
                lastError = error
                retryCount += 1
                
                if retryCount < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    delay *= request.retryPolicy.backoffMultiplier
                }
            }
        }
        
        throw lastError ?? APIError.invalidResponse
    }
    
    private func performRequest<T: Codable>(_ request: APIRequest, responseType: T.Type) async throws -> T {
        let startTime = Date()
        
        // Build URL
        var urlComponents = URLComponents(string: APIConfiguration.baseURL + request.endpoint)
        if let parameters = request.parameters, request.method == .get {
            urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents?.url else {
            throw APIError.invalidURL
        }
        
        // Create request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = APIConfiguration.timeout
        
        // Add headers
        var headers = request.headers ?? [:]
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        headers["X-App-Version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        headers["X-Platform"] = "iOS"
        headers["X-Device-Id"] = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
        
        if request.requiresAuth {
            headers["Authorization"] = "Bearer \(authToken)"
        }
        
        for (key, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body
        if let body = request.body {
            urlRequest.httpBody = body
        } else if let parameters = request.parameters, request.method != .get {
            urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        }
        
        // Track request
        let requestId = UUID().uuidString
        trackRequest(requestId: requestId, request: request)
        
        do {
            // Perform request
            let (data, response) = try await session.data(for: urlRequest)
            
            // Track response time
            let responseTime = Date().timeIntervalSince(startTime)
            trackResponse(requestId: requestId, response: response, responseTime: responseTime)
            
            // Handle response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Check for rate limiting
            if httpResponse.statusCode == 429 {
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                    .flatMap { Double($0) }
                throw APIError.rateLimited(retryAfter: retryAfter)
            }
            
            // Check for server errors
            if httpResponse.statusCode >= 500 {
                let errorMessage = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage?.message)
            }
            
            // Check for client errors
            if httpResponse.statusCode >= 400 {
                if httpResponse.statusCode == 401 {
                    throw APIError.unauthorized
                }
                
                let errorMessage = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage?.message)
            }
            
            // Success - decode response
            let apiResponse = try JSONDecoder().decode(APIResponseWrapper<T>.self, from: data)
            
            guard let responseData = apiResponse.data else {
                throw APIError.noData
            }
            
            // Cache response if applicable
            if request.method == .get && request.cachePolicy != .none {
                let cacheKey = createCacheKey(for: request)
                let cacheTTL = getCacheTTL(from: httpResponse)
                await cache.cache(data: data, for: cacheKey, headers: httpResponse.allHeaderFields as? [String: String] ?? [:], ttl: cacheTTL)
            }
            
            // Update request timestamps for rate limiting
            requestTimestamps.append(Date())
            cleanupOldTimestamps()
            
            return responseData
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createCacheKey(for request: APIRequest) -> String {
        var components = [request.endpoint, request.method.rawValue]
        
        if let parameters = request.parameters {
            let sortedParams = parameters.keys.sorted().map { "\($0)=\(parameters[$0] ?? "")" }
            components.append(contentsOf: sortedParams)
        }
        
        return components.joined(separator: "_")
    }
    
    private func getCacheTTL(from response: HTTPURLResponse) -> TimeInterval? {
        // Check Cache-Control header
        if let cacheControl = response.value(forHTTPHeaderField: "Cache-Control") {
            let directives = cacheControl.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            for directive in directives {
                if directive.starts(with: "max-age=") {
                    let value = directive.dropFirst(8)
                    if let ttl = TimeInterval(value) {
                        return ttl
                    }
                }
            }
        }
        
        // Default cache duration
        return APIConfiguration.cacheDuration
    }
    
    private func isRateLimited() -> Bool {
        let recentRequests = requestTimestamps.filter { Date().timeIntervalSince($0) < rateLimitWindow }
        return recentRequests.count >= rateLimitMaxRequests
    }
    
    private func calculateRetryAfter() -> TimeInterval {
        let recentRequests = requestTimestamps.filter { Date().timeIntervalSince($0) < rateLimitWindow }
        if let oldestRequest = recentRequests.first {
            return rateLimitWindow - Date().timeIntervalSince(oldestRequest)
        }
        return rateLimitWindow
    }
    
    private func cleanupOldTimestamps() {
        requestTimestamps = requestTimestamps.filter { Date().timeIntervalSince($0) < rateLimitWindow }
    }
    
    // MARK: - Request Queue
    
    private func queueRequest(_ request: APIRequest) {
        requestQueue.append(request)
        saveQueuedRequests()
    }
    
    private func processQueuedRequests() {
        guard !requestQueue.isEmpty else { return }
        
        let queue = requestQueue
        requestQueue.removeAll()
        
        for request in queue {
            Task {
                do {
                    // Fix: Cast the generic method properly
                    _ = try await self.request(EmptyResponse.self, endpoint: request.endpoint, method: request.method)
                } catch {
                    print("Failed to process queued request: \(error)")
                }
            }
        }
        
        saveQueuedRequests()
    }
    
    private func saveQueuedRequests() {
        // Save queued requests for persistence across app launches
        if let encoded = try? JSONEncoder().encode(requestQueue) {
            UserDefaults.standard.set(encoded, forKey: "queuedRequests")
        }
    }
    
    private func loadQueuedRequests() {
        if let data = UserDefaults.standard.data(forKey: "queuedRequests"),
           let requests = try? JSONDecoder().decode([APIRequest].self, from: data) {
            requestQueue = requests
        }
    }
    
    // MARK: - Analytics
    
    private func trackRequest(requestId: String, request: APIRequest) {
        // Simplified tracking - remove AnalyticsService dependency
        print("Tracking request: \(request.endpoint)")
    }
    
    private func trackResponse(requestId: String, response: URLResponse?, responseTime: TimeInterval) {
        if let httpResponse = response as? HTTPURLResponse {
            print("Response: \(httpResponse.statusCode) in \(responseTime)s")
        }
    }
}

// MARK: - Specific API Endpoints
extension APIService {
    
    // City Sentiments
    func fetchCitySentiments() async throws -> [CitySentiment] {
        return try await request(
            [CitySentiment].self,
            endpoint: "/sentiments",
            cachePolicy: .returnCacheElseLoad
        )
    }
    
    // User Profile
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        return try await request(
            UserProfile.self,
            endpoint: "/users/\(userId)",
            cachePolicy: .returnCacheElseLoad
        )
    }
    
    // Submit User Emotion
    func submitEmotion(emotion: String, location: String, coordinates: CLLocationCoordinate2D?) async throws {
        let body: [String: Any] = [
            "emotion": emotion,
            "location": location,
            "latitude": coordinates?.latitude ?? 0,
            "longitude": coordinates?.longitude ?? 0,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        let data = try JSONSerialization.data(withJSONObject: body)
        
        _ = try await request(
            EmptyResponse.self,
            endpoint: "/emotions",
            method: .post,
            body: data,
            cachePolicy: .none
        )
    }
    
    // Recommendations
    func fetchRecommendations(for userId: String) async throws -> [RecommendableItem] {
        return try await request(
            [RecommendableItem].self,
            endpoint: "/recommendations/\(userId)",
            cachePolicy: .returnCacheElseLoad
        )
    }
    
    // Notifications
    func registerDeviceToken(_ token: String, userId: String) async throws {
        let body: [String: Any] = [
            "token": token,
            "userId": userId,
            "platform": "iOS",
            "deviceId": UIDevice.current.identifierForVendor?.uuidString ?? ""
        ]
        
        let data = try JSONSerialization.data(withJSONObject: body)
        
        _ = try await request(
            EmptyResponse.self,
            endpoint: "/notifications/register",
            method: .post,
            body: data,
            cachePolicy: .none
        )
    }
}

// MARK: - Network Monitoring View
struct NetworkStatusView: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        HStack {
            Circle()
                .fill(networkMonitor.isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(networkMonitor.isConnected ? "Connected" : "Offline")
                .font(.caption)
                .foregroundColor(networkMonitor.isConnected ? .green : .red)
            
            if let type = networkMonitor.connectionType {
                Text("(\(connectionTypeName(type)))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if networkMonitor.isExpensive {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            if networkMonitor.isConstrained {
                Image(systemName: "tortoise.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
    
    private func connectionTypeName(_ type: NWInterface.InterfaceType) -> String {
        switch type {
        case .wifi: return "WiFi"
        case .cellular: return "Cellular"
        case .wiredEthernet: return "Ethernet"
        default: return "Unknown"
        }
    }
}
