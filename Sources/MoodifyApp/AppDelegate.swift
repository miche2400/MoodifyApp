//
//  AppDelegate.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 27/01/2025.
//
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("App launched successfully")
        return true
    }

    // Handle custom URL scheme redirects
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Ensure the URL scheme matches the expected one
        guard url.scheme == "moodifyapp" else {
            print("Error: Unrecognized URL scheme")
            return false
        }

        // Handle the Spotify redirect
        SpotifyAuthManager.shared.handleRedirect(url: url) { success in
            DispatchQueue.main.async {
                if success {
                    print("Spotify authentication successful!")
                    NotificationCenter.default.post(name: Notification.Name("SpotifyLoginSuccess"), object: nil)
                } else {
                    print("Spotify authentication failed.")
                    NotificationCenter.default.post(name: Notification.Name("SpotifyLoginFailure"), object: nil)
                }
            }
        }

        return true
    }
}
