//
//  LandingScreen.swift
//  MoodGpt
//
//  Splash screen with fast transition to main app
//

import SwiftUI

struct LandingScreen: View {
    @State private var showMainApp = false
    @State private var pulseAnimation = false
    @State private var fadeIn = false
    @State private var subtitleVisible = false
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.7),
                    Color.pink.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Main Logo/Icon
                ZStack {
                    // Pulsing background circle
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.0 : 0.6)
                        .animation(
                            .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: false),
                            value: pulseAnimation
                        )
                    
                    // Icon container
                    Circle()
                        .fill(Color.white)
                        .frame(width: 140, height: 140)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .overlay(
                            // Emoji icon
                            Text("🌍")
                                .font(.system(size: 80))
                                .scaleEffect(fadeIn ? 1.0 : 0.5)
                                .opacity(fadeIn ? 1.0 : 0.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: fadeIn)
                        )
                }
                
                VStack(spacing: 16) {
                    // App name
                    Text("MoodGPT")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        .scaleEffect(fadeIn ? 1.0 : 0.8)
                        .opacity(fadeIn ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.3), value: fadeIn)
                    
                    // Tagline
                    Text("Feel the pulse of your city")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                        .opacity(subtitleVisible ? 1.0 : 0.0)
                        .offset(y: subtitleVisible ? 0 : 20)
                        .animation(.easeOut(duration: 0.3).delay(0.1), value: subtitleVisible)
                }
                
                Spacer()
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                    .opacity(fadeIn ? 1.0 : 0.0)
                    .animation(.easeIn(duration: 0.2).delay(0.2), value: fadeIn)
                
                Spacer(minLength: 50)
            }
        }
        .onAppear {
            // Start animations
            withAnimation {
                fadeIn = true
                pulseAnimation = true
            }
            
            // Show subtitle after a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                subtitleVisible = true
            }
            
            // Transition to main app after 0.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showMainApp = true
                }
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            MainAppView()
                .environmentObject(AppState.shared)
        }
    }
}

// Alternative version with city mood animations - also with 0.5 second duration
struct LandingScreenWithCityMoods: View {
    @State private var showMainApp = false
    @State private var emojiAnimations: [Bool] = Array(repeating: false, count: 6)
    @State private var fadeIn = false
    
    let cityEmojis = ["😊", "😎", "😢", "😡", "😌", "🤔"]
    let emojiPositions: [(x: CGFloat, y: CGFloat)] = [
        (-100, -200), (120, -150), (-130, 100),
        (100, 180), (-80, 50), (90, -50)
    ]
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.7),
                    Color.pink.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating city mood emojis
            ForEach(0..<cityEmojis.count, id: \.self) { index in
                Text(cityEmojis[index])
                    .font(.system(size: 36))
                    .opacity(emojiAnimations[index] ? 0.6 : 0.0)
                    .scaleEffect(emojiAnimations[index] ? 1.0 : 0.3)
                    .offset(
                        x: emojiPositions[index].x + (emojiAnimations[index] ? 0 : -20),
                        y: emojiPositions[index].y + (emojiAnimations[index] ? 0 : -20)
                    )
                    .animation(
                        .easeOut(duration: 0.3)
                        .delay(Double(index) * 0.05),
                        value: emojiAnimations[index]
                    )
            }
            
            VStack(spacing: 30) {
                Spacer()
                
                // Main content
                VStack(spacing: 20) {
                    // Icon with pulse animation
                    ZStack {
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(Color.white.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                                .frame(width: 120 + CGFloat(i * 30), height: 120 + CGFloat(i * 30))
                                .scaleEffect(fadeIn ? 1.0 : 0.5)
                                .opacity(fadeIn ? (0.6 - Double(i) * 0.2) : 0.0)
                                .animation(
                                    .easeOut(duration: 0.4)
                                    .delay(Double(i) * 0.1),
                                    value: fadeIn
                                )
                        }
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                            .overlay(
                                Text("🌆")
                                    .font(.system(size: 60))
                            )
                            .scaleEffect(fadeIn ? 1.0 : 0.5)
                            .opacity(fadeIn ? 1.0 : 0.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: fadeIn)
                    }
                    
                    VStack(spacing: 12) {
                        Text("MoodGPT")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        
                        Text("Feel the pulse of your city")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                    }
                    .scaleEffect(fadeIn ? 1.0 : 0.8)
                    .opacity(fadeIn ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.3), value: fadeIn)
                }
                
                Spacer()
                
                // Loading dots animation
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .opacity(fadeIn ? 1.0 : 0.0)
                            .scaleEffect(fadeIn ? 1.0 : 0.0)
                            .animation(
                                .easeInOut(duration: 0.2)
                                .delay(Double(i) * 0.05 + 0.1),
                                value: fadeIn
                            )
                    }
                }
                
                Spacer(minLength: 50)
            }
        }
        .onAppear {
            // Start animations
            withAnimation {
                fadeIn = true
            }
            
            // Animate emojis
            for i in 0..<cityEmojis.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                    emojiAnimations[i] = true
                }
            }
            
            // Transition to main app after 0.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showMainApp = true
                }
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            MainAppView()
                .environmentObject(AppState.shared)
        }
    }
}

// Preview
struct LandingScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LandingScreen()
                .previewDisplayName("Simple Landing")
            
            LandingScreenWithCityMoods()
                .previewDisplayName("City Moods Landing")
        }
    }
}
