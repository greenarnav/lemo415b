//
//  AuthenticationView.swift
//  MoodGpt
//
//  Sign in screen for unauthenticated users
//

import SwiftUI
import AuthenticationServices  // Only import what works

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 102/255, green: 126/255, blue: 234/255),
                    Color(red: 118/255, green: 75/255, blue: 162/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo and title
                VStack(spacing: 20) {
                    Image(systemName: "face.smiling.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                    
                    Text("MoodGPT")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Feel the pulse of your city")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Sign-in buttons
                VStack(spacing: 16) {
                    // Custom Google Sign-In Button
                    Button(action: {
                        Task {
                            isLoading = true
                            await authService.signInWithGoogle()
                            isLoading = false
                            
                            if let error = authService.error {
                                errorMessage = error
                                showError = true
                            }
                        }
                    }) {
                        HStack {
                            // Use a system image or custom asset
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.red)
                            
                            Text("Continue with Google")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(27)
                        .shadow(radius: 4)
                    }
                    .disabled(isLoading)
                    
                    // Apple Sign-In
                    SignInWithAppleButton(
                        .continue,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                // Handle Apple sign-in
                                handleAppleSignIn(authorization)
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    )
                    .frame(height: 54)
                    .cornerRadius(27)
                    .shadow(radius: 4)
                    .disabled(isLoading)
                    
                    // Continue as Guest
                    Button(action: {
                        // Skip authentication for now
                        // This would need to be handled in your app logic
                    }) {
                        Text("Continue as Guest")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(27)
                            .overlay(
                                RoundedRectangle(cornerRadius: 27)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal, 40)
                
                // Terms and Privacy
                VStack(spacing: 8) {
                    Text("By continuing, you agree to our")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 4) {
                        Button("Terms of Service") {
                            // Open terms
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .underline()
                        
                        Text("and")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button("Privacy Policy") {
                            // Open privacy policy
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .underline()
                    }
                }
                
                Spacer(minLength: 50)
            }
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleAppleSignIn(_ authorization: ASAuthorization) {
        // Handle Apple Sign-In
        // This would need to be implemented based on your backend
    }
}
