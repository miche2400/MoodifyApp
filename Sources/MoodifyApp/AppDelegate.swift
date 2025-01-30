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

        // Quick UI setup
        setupQuickLaunchContent()

        // Defer heavy initializations
        performDeferredInitializations()

        return true
    }

    func setupQuickLaunchContent() {
        // Initialize the window and set a basic view controller if not using Storyboards
        window = UIWindow()
        window?.rootViewController = ViewController() // Adjust ViewController to your actual initial view controller
        window?.makeKeyAndVisible()
        print("🖥️ UI setup complete")
    }

    func performDeferredInitializations() {
        DispatchQueue.global(qos: .background).async {
            // Perform heavy tasks here like data preloading or complex setup
            print("⏳ Performing deferred initializations...")
        }
    }

    // MARK: - Handle Custom URL Scheme Redirects
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        print("🔄 Received URL: \(url.absoluteString)")

        // Ensure the URL scheme matches the expected one
        guard url.scheme == "moodifyapp" else {
            print("❌ Error: Unrecognized URL scheme")
            return false
        }

        // Handle the Spotify redirect
        print("🔄 Handling Spotify redirect...")
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

// MARK: - Basic ViewController for UI
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white // Set a default background color
        print("🎨 ViewController initialized")
    }
}
