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
    @State private var isLaunchScreenVisible: Bool = true
    @State private var isLoggedIn: Bool = false // Track Spotify login state

    var body: some Scene {
        WindowGroup {
            if isLaunchScreenVisible {
                LaunchScreen()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isLaunchScreenVisible = false
                        }
                    }
            } else if isLoggedIn {
                ContentView() // Show questionnaire after successful login
            } else {
                SpotifyLoginView(isLoggedIn: $isLoggedIn) // Show Spotify login screen
                    .onAppear {
                        setupNotificationListeners()
                    }
            }
        }
    }

    // MARK: - Notification Setup
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(forName: Notification.Name("SpotifyLoginSuccess"), object: nil, queue: .main) { _ in
            isLoggedIn = true
        }

        NotificationCenter.default.addObserver(forName: Notification.Name("SpotifyLoginFailure"), object: nil, queue: .main) { _ in
            isLoggedIn = false
        }
    }
}
