//
//  AppDelegate.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 17/12/2024.
//
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    override init() {
           super.init()
           print("🛠 [DEBUG] AppDelegate INIT called!")  
       }

    static let spotifyLoginSuccessNotification = Notification.Name("SpotifyLoginSuccess")
    static let spotifyLoginFailureNotification = Notification.Name("SpotifyLoginFailure")

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        print("🔄 [DEBUG] AppDelegate received URL: \(url.absoluteString)")

        // Ensure the URL scheme matches what is defined in Info.plist
        guard let scheme = url.scheme, scheme.lowercased() == "moodifyapp" else {
            print("❌ [ERROR] Invalid URL Scheme: \(url.scheme ?? "None")")
            return false
        }

        // Validate URL host
        guard let host = url.host, host == "callback" else {
            print("⚠️ [WARNING] Unexpected URL host: \(url.host ?? "None")")
            return false
        }

        // Send the URL to the SpotifyAuthManager
        SpotifyAuthManager.shared.handleRedirect(url: url) { success in
            DispatchQueue.main.async {
                if success {
                    print("✅ [DEBUG] Token exchange successful!")
                    NotificationCenter.default.post(
                        name: Notification.Name("SpotifyLoginSuccess"),
                        object: nil
                    )
                } else {
                    print("❌ [ERROR] Token exchange failed!")
                    NotificationCenter.default.post(
                        name: Notification.Name("SpotifyLoginFailure"),
                        object: nil
                    )
                }
            }
        }

        return true
    }

}
