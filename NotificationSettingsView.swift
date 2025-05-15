//
//  NotificationSettingsView.swift
//  MoodGpt
//
//  Created by Test on 5/8/25.
//


import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showPermissionAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.white)
                Text("Notifications")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            // Status
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Status:")
                        .foregroundColor(.white)
                    
                    if notificationManager.isAuthorized {
                        Text("Enabled")
                            .foregroundColor(.green)
                            .bold()
                    } else {
                        Text("Disabled")
                            .foregroundColor(.red)
                            .bold()
                    }
                }
                
                if !notificationManager.isAuthorized {
                    Button(action: {
                        requestPermission()
                    }) {
                        Text("Enable Notifications")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.6))
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.15))
            .cornerRadius(10)
            
            // Test Notifications Section
            if notificationManager.isAuthorized {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Test Notifications")
                        .foregroundColor(.white)
                        .font(.subheadline)
                    
                    Text("Send 10 test notifications every 30 seconds")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.caption)
                    
                    Button(action: {
                        notificationManager.scheduleTestNotifications()
                    }) {
                        Text("Send Test Notifications")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.6))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        notificationManager.cancelAllNotifications()
                    }) {
                        Text("Cancel All Notifications")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.6))
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(10)
                
                // Pending Notifications
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pending Notifications: \(notificationManager.pendingNotifications.count)")
                        .foregroundColor(.white)
                        .font(.subheadline)
                    
                    Button(action: {
                        notificationManager.updatePendingNotifications()
                    }) {
                        Text("Refresh")
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(8)
                    }
                    
                    if !notificationManager.pendingNotifications.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(notificationManager.pendingNotifications, id: \.identifier) { request in
                                    if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger, 
                                       let content = request.content as? UNNotificationContent {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(content.title)
                                                    .foregroundColor(.white)
                                                    .font(.caption)
                                                Text(content.body)
                                                    .foregroundColor(.white.opacity(0.7))
                                                    .font(.caption2)
                                            }
                                            Spacer()
                                            if trigger.repeats {
                                                Text("Repeating")
                                                    .foregroundColor(.orange)
                                                    .font(.caption2)
                                            } else {
                                                Text("\(Int(trigger.timeInterval))s")
                                                    .foregroundColor(.gray)
                                                    .font(.caption2)
                                            }
                                        }
                                        .padding(8)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                    } else {
                        Text("No pending notifications")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.caption)
                            .padding(8)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $showPermissionAlert) {
            Alert(
                title: Text("Notifications Disabled"),
                message: Text("Please enable notifications in your device settings to use this feature."),
                primaryButton: .default(Text("Settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            notificationManager.checkAuthorizationStatus()
            notificationManager.updatePendingNotifications()
        }
    }
    
    private func requestPermission() {
        notificationManager.requestPermission()
    }
}

#Preview {
    NotificationSettingsView()
        .environmentObject(NotificationManager.shared)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.5), .white.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}