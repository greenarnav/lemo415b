//
//  AuthenticationService.swift
//  MoodGpt
//

import Foundation
import SwiftUI
import AuthenticationServices
import CryptoKit

// MARK: - User Model
struct User: Codable {
    let id: String
    let email: String
    let fullName: String
    let provider: AuthProvider
    let profileImageUrl: String?
    let createdAt: Date
    let lastLoginAt: Date
    var authToken: String?
    var refreshToken: String?
    var tokenExpiresAt: Date?
}

enum AuthProvider: String, Codable {
    case google
    case apple
    case email
    case guest
}

// MARK: - Authentication Service
@MainActor
class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var currentUser: User?
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var error: String?
    
    private let keychain = KeychainManager()
    
    private init() {
        // Check for existing session on init
        Task {
            await checkExistingSession()
        }
    }
    
    // MARK: - Session Management
    
    func checkExistingSession() async {
        // Try to restore session from keychain
        if let userData = keychain.getData(for: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            
            // Check if token is still valid
            if let expiresAt = user.tokenExpiresAt, expiresAt > Date() {
                self.currentUser = user
                self.isSignedIn = true
            } else {
                // Token expired, sign out
                await signOut()
            }
        }
    }
    
    // MARK: - Google Sign-In (Mock Implementation)
    
    func signInWithGoogle() async {
        isLoading = true
        error = nil
        
        // Mock implementation - create a test user
        let mockUser = User(
            id: UUID().uuidString,
            email: "test@example.com",
            fullName: "Test User",
            provider: .google,
            profileImageUrl: nil,
            createdAt: Date(),
            lastLoginAt: Date(),
            authToken: "mock_token_\(UUID().uuidString)",
            refreshToken: "mock_refresh_\(UUID().uuidString)",
            tokenExpiresAt: Date().addingTimeInterval(3600)
        )
        
        await saveUser(mockUser)
        isLoading = false
    }
    
    // MARK: - Apple Sign-In
    
    func handleAppleSignIn(_ authorization: ASAuthorization) async {
        isLoading = true
        error = nil
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            error = "Invalid Apple ID credentials"
            isLoading = false
            return
        }
        
        // Get user data
        let userIdentifier = appleIDCredential.user
        let fullName = appleIDCredential.fullName
        let email = appleIDCredential.email ?? "apple_user@example.com"
        
        // Create user object
        let user = User(
            id: userIdentifier,
            email: email,
            fullName: "\(fullName?.givenName ?? "") \(fullName?.familyName ?? "")".trimmingCharacters(in: .whitespaces),
            provider: .apple,
            profileImageUrl: nil,
            createdAt: Date(),
            lastLoginAt: Date(),
            authToken: "apple_token_\(UUID().uuidString)",
            refreshToken: "apple_refresh_\(UUID().uuidString)",
            tokenExpiresAt: Date().addingTimeInterval(3600)
        )
        
        await saveUser(user)
        isLoading = false
    }
    
    // MARK: - Skip Authentication (Guest)
    
    func skipAuthentication() {
        let guestUser = User(
            id: "guest_\(UUID().uuidString)",
            email: "guest@moodgpt.com",
            fullName: "Guest User",
            provider: .guest,
            profileImageUrl: nil,
            createdAt: Date(),
            lastLoginAt: Date(),
            authToken: "guest_token_\(UUID().uuidString)",
            refreshToken: nil,
            tokenExpiresAt: Date().addingTimeInterval(86400) // 24 hours
        )
        
        Task {
            await saveUser(guestUser)
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        isLoading = true
        
        // Clear local data
        keychain.delete(key: "currentUser")
        currentUser = nil
        isSignedIn = false
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func saveUser(_ user: User) async {
        currentUser = user
        isSignedIn = true
        
        // Save to keychain
        if let encoded = try? JSONEncoder().encode(user) {
            keychain.save(data: encoded, for: "currentUser")
        }
    }
    
    func refreshTokenIfNeeded() async {
        // Mock implementation - in production, this would call your backend
        if let user = currentUser {
            var updatedUser = user
            updatedUser.tokenExpiresAt = Date().addingTimeInterval(3600)
            await saveUser(updatedUser)
        }
    }
}

// MARK: - Keychain Manager
class KeychainManager {
    func save(data: Data, for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getData(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }
    
    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
