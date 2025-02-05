//
//  MoodifyAppApp.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 17/12/2024.
//

import SwiftUI

@main
struct MoodifyAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("UserLoggedIn") private var isLoggedIn: Bool = false // Persistent login state

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isLoggedIn {
                    ContentView()
                        .transition(.opacity)
                } else {
                    SpotifyLoginView(isLoggedIn: $isLoggedIn)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isLoggedIn)
            .onAppear {
                print("🔄 App started, checking login state: \(isLoggedIn)")
                setupNotificationListeners()
            }
        }
    }

    // MARK: - Notification Setup for Spotify Login
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(forName: Notification.Name("SpotifyLoginSuccess"), object: nil, queue: .main) { _ in
            DispatchQueue.main.async {
                print("✅ Spotify login detected! Updating state...")
                isLoggedIn = true
            }
        }

        NotificationCenter.default.addObserver(forName: Notification.Name("SpotifyLoginFailure"), object: nil, queue: .main) { _ in
            DispatchQueue.main.async {
                print("❌ Spotify login failed. Staying on login screen.")
                isLoggedIn = false
            }
        }
    }
}
