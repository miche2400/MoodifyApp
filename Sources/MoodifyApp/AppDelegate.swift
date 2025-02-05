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

        guard url.scheme == "moodifyapp" else {
            print("❌ Error: Unrecognized URL scheme")
            return false
        }

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
