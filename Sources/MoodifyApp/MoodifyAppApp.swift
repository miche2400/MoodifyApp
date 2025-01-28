//
//  MoodifyAppApp.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 17/12/2024.
//

import SwiftUI

@main
struct MoodifyAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate // Link AppDelegate
    @State private var isLoggedIn: Bool = false // Track Spotify login state
    @State private var isLaunchScreenVisible: Bool = true // Show launch screen first

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isLaunchScreenVisible {
                    Color.white.ignoresSafeArea() // Prevents black screen
                } else if isLoggedIn {
                    ContentView() // Show questionnaire after login
                } else {
                    SpotifyLoginView(isLoggedIn: $isLoggedIn)
                }
            }
            .onAppear {
                setupNotificationListeners()
                showLaunchScreen()
            }
        }
    }

    // MARK: - Show LaunchScreen for 2 Seconds
    private func showLaunchScreen() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLaunchScreenVisible = false
        }
    }

    // MARK: - Notification Setup for Spotify Login
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(forName: Notification.Name("SpotifyLoginSuccess"), object: nil, queue: .main) { _ in
            DispatchQueue.main.async {
                isLoggedIn = true
            }
        }

        NotificationCenter.default.addObserver(forName: Notification.Name("SpotifyLoginFailure"), object: nil, queue: .main) { _ in
            DispatchQueue.main.async {
                isLoggedIn = false
            }
        }
    }
}
