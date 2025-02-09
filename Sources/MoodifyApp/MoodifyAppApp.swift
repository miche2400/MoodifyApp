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
                validateUserSession()
                debugStoredTokens() // Added to debug stored tokens
            }
        }
    }

    // MARK: - Validate User Session on App Launch
    private func validateUserSession() {
        if SpotifyAuthManager.shared.isTokenValid {
            print("✅ User has a valid token. Skipping login.")
            isLoggedIn = true
        } else {
            print("⚠️ No valid token found. Attempting refresh...")

            SpotifyAuthManager.shared.refreshAccessToken { success in
                DispatchQueue.main.async {
                    if success {
                        print("✅ Token refreshed, logging in.")
                        isLoggedIn = true
                    } else {
                        print("❌ Token refresh failed. User must log in again.")
                        isLoggedIn = false
                        debugStoredTokens() // Added to check stored tokens when refresh fails
                    }
                }
            }
        }
    }

    // MARK: - Notification Setup for Spotify Login
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(forName: Notification.Name("SpotifyLoginSuccess"), object: nil, queue: .main) { _ in
            DispatchQueue.main.async {
                print("✅ Spotify login detected! Updating state...")
                isLoggedIn = true
                debugStoredTokens() // Added to check tokens upon successful login
            }
        }

        NotificationCenter.default.addObserver(forName: Notification.Name("SpotifyLoginFailure"), object: nil, queue: .main) { _ in
            DispatchQueue.main.async {
                print("❌ Spotify login failed. Staying on login screen.")
                isLoggedIn = false
                debugStoredTokens() // Added to check tokens upon failed login
            }
        }
    }

    // MARK: - Debugging Stored Tokens
    private func debugStoredTokens() {
        let storedAccessToken = UserDefaults.standard.string(forKey: "SpotifyAccessToken") ?? "None"
        let storedRefreshToken = UserDefaults.standard.string(forKey: "SpotifyRefreshToken") ?? "None"
        let tokenExpiration = UserDefaults.standard.object(forKey: "SpotifyTokenExpirationDate") as? Date ?? Date.distantPast

        print("🔍 Stored Access Token: \(storedAccessToken.prefix(10))...")
        print("🔍 Stored Refresh Token: \(storedRefreshToken.prefix(10))...")
        print("🕒 Token Expiration Date: \(tokenExpiration)")
    }
}
