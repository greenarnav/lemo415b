//
//  NotificationBannerView.swift
//  MoodGpt
//
//  Created by Test on 5/12/25.
//


//
//  NotificationBannerView.swift
//  MoodGpt
//

import SwiftUI

struct NotificationBannerView: View {
    let notification: RemoteNotificationService.NotificationData
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.white)
                
                Text("New Notification")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Text(notification.body)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(notification.timestamp, style: .relative)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.purple.opacity(0.8), .blue.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    isShowing = false
                }
            }
        }
    }
}

// Add this to your MainAppView or as an overlay to your root view
struct NotificationOverlay: View {
    @StateObject private var remoteNotifications = RemoteNotificationService.shared
    @State private var showingNotification = false
    @State private var currentNotification: RemoteNotificationService.NotificationData?
    
    var body: some View {
        ZStack {
            if showingNotification, let notification = currentNotification {
                VStack {
                    NotificationBannerView(
                        notification: notification,
                        isShowing: $showingNotification
                    )
                    Spacer()
                }
                .animation(.spring(), value: showingNotification)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewRemoteNotification"))) { notification in
            if let notificationData = notification.object as? RemoteNotificationService.NotificationData {
                currentNotification = notificationData
                withAnimation {
                    showingNotification = true
                }
            }
        }
    }
}