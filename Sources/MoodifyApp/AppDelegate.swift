//
//  AppDelegate.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 17/12/2024.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("🚀 App launched successfully")
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("🔄 Received redirect URL: \(url.absoluteString)")

        // Ensure the URL scheme is valid and contains the expected components
        guard url.scheme == "moodifyapp", url.host != nil else {
            print("❌ Error: Invalid or unrecognized URL scheme")
            return false
        }

        // Debugging: Print query parameters from URL
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            print("🔍 URL Components: \(components)")
            if let queryItems = components.queryItems {
                for item in queryItems {
                    print("🔹 \(item.name): \(item.value ?? "nil")")
                }
            }
        }

        // Handle the authentication redirect
        SpotifyAuthManager.shared.handleRedirect(url: url) { success in
            DispatchQueue.main.async {
                if success {
                    print("✅ Spotify authentication successful!")
                    NotificationCenter.default.post(name: Notification.Name("SpotifyLoginSuccess"), object: nil)
                } else {
                    print("❌ Spotify authentication failed.")
                    NotificationCenter.default.post(name: Notification.Name("SpotifyLoginFailure"), object: nil)
                }
            }
        }
        return true
    }
}
