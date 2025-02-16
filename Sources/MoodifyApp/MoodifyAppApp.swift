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
    @AppStorage("UserCompletedQuestionnaire") private var hasCompletedQuestionnaire: Bool = false // Track questionnaire completion
    @State private var isCheckingSession: Bool = true // Prevents flickering before session validation
    @State private var navigateToQuestionnaire: Bool = false // Handles navigation to questionnaire

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ZStack {
                    if isCheckingSession {
                        ProgressView("Checking session...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.5)
                            .onAppear {
                                validateSession()
                            }
                    } else if isLoggedIn {
                        ContentView()
                    } else {
                        SpotifyLoginView(isLoggedIn: $isLoggedIn, navigateToQuestionnaire: $navigateToQuestionnaire)
                    }
                }
                .onAppear {
                    setupNotificationListeners()
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isLoggedIn)
        }
    }

    // MARK: - Validate Spotify Session
    private func validateSession() {
        print("🔍 Validating user session on app launch...")

        if let accessToken = UserDefaults.standard.string(forKey: "SpotifyAccessToken"),
           !accessToken.isEmpty,
           SpotifyAuthManager.shared.isTokenValid { 
            print("✅ Valid Spotify token found.")
            isLoggedIn = true
        } else {
            print("❌ No valid token found. Redirecting to login.")
            isLoggedIn = false
        }

        // Ensure session check completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isCheckingSession = false
        }
    }

    // MARK: - Notification Setup for Spotify Login
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("SpotifyLoginSuccess"),
            object: nil,
            queue: .main) { _ in
                DispatchQueue.main.async {
                    print("✅ Spotify login successful! Navigating to ContentView.")
                    self.isLoggedIn = true
                    self.navigateToQuestionnaire = true
                    self.isCheckingSession = false // Ensure navigation updates correctly
                }
            }

        NotificationCenter.default.addObserver(
            forName: Notification.Name("SpotifyLoginFailure"),
            object: nil,
            queue: .main) { _ in
                DispatchQueue.main.async {
                    print("❌ Spotify login failed. User needs to log in again.")
                    self.isLoggedIn = false
                    self.navigateToQuestionnaire = false
                    self.isCheckingSession = false // Ensure UI updates correctly
                }
            }
    }
}
