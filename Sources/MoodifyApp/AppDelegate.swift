//
//  AppDelegate.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 17/12/2024.
//

import UIKit
import SwiftUI
import Supabase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    // MARK: - App Storage Variables
    @AppStorage("UserLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("SpotifyAccessToken") private var accessToken: String?

    // MARK: - State Variables
    private var isCheckingSession = true

    override init() {
        super.init()
        print("🛠 [DEBUG] AppDelegate INIT called!")
        setupNotificationListeners()
    }

    // MARK: - Application Launch
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("[DEBUG] AppDelegate didFinishLaunchingWithOptions called.")

        self.window = UIWindow(frame: UIScreen.main.bounds)
        let initialView = UIHostingController(rootView: ProgressView("Loading..."))
        self.window?.rootViewController = initialView
        self.window?.makeKeyAndVisible()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateRootView()
        }
        return true
    }

    // MARK: - Update Root View
    private func updateRootView() {
        print("[DEBUG] Updating Root View...")
        let rootView = determineRootView()
        let hostingController = UIHostingController(rootView: rootView)
        DispatchQueue.main.async {
            self.window?.rootViewController = hostingController
        }
    }

    // MARK: - Determine Root View
    private func determineRootView() -> some View {
        if isCheckingSession {
            return AnyView(
                ProgressView("Checking session...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.5)
                    .onAppear { self.checkLoginStatus() }
            )
        } else if isLoggedIn {
            print("[DEBUG] Showing ContentView.")
            return AnyView(ContentView())
        } else {
            print("[DEBUG] Showing Spotify Login View.")
            return AnyView(SpotifyLoginView(isLoggedIn: .constant(false), navigateToQuestionnaire: .constant(false)))
        }
    }

    // MARK: - Check Login Status
    private func checkLoginStatus() {
        print("Checking if user is logged in...")
        if isLoggedIn {
            print("User is logged in. Checking token validity...")
            if let token = SpotifyAuthManager.shared.getAccessToken(), !token.isEmpty {
                print("Valid Spotify token found.")
                DispatchQueue.main.async {
                    self.isCheckingSession = false
                    self.updateRootView()
                }
            } else {
                print("Token is invalid or expired. Logging out user.")
                logoutUser()
            }
        } else {
            print("No valid session found. Showing login screen...")
            DispatchQueue.main.async {
                self.isCheckingSession = false
                self.updateRootView()
            }
        }
    }

    // MARK: - Logout User (If Token is Expired)
    func logoutUser() {
        print("Logging out user and showing login screen.")
        DispatchQueue.main.async {
            self.isLoggedIn = false
            self.accessToken = nil
            self.updateRootView()
        }
    }

    // MARK: - Handle Spotify Redirect
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool
    {
        print("[DEBUG] AppDelegate received URL: \(url.absoluteString)")

        // Check for custom Supabase callback (if implemented)
        if let scheme = url.scheme, scheme.lowercased() == "moodifyapp-supabase",
           let host = url.host, host.lowercased() == "auth" {
            print("[DEBUG] Handling Supabase callback: \(url.absoluteString)")
            // TODO: Handle custom Supabase callback if needed.
            return true
        }

        // Handle Spotify callback
        if let scheme = url.scheme, scheme.lowercased() == "moodifyapp",
           let host = url.host, host.lowercased() == "callback" {
            print("[DEBUG] Handling Spotify callback: \(url.absoluteString)")
            SpotifyAuthManager.shared.handleRedirect(url: url) { success in
                DispatchQueue.main.async {
                    if success {
                        print("[DEBUG] Token exchange successful in AppDelegate")
                        self.isLoggedIn = true
                        self.updateRootView()
                        NotificationCenter.default.post(name: Notification.Name("SpotifyLoginSuccess"), object: nil)
                    } else {
                        print("[ERROR] Token exchange failed in AppDelegate")
                        self.isLoggedIn = false
                        self.updateRootView()
                        NotificationCenter.default.post(name: Notification.Name("SpotifyLoginFailure"), object: nil)
                    }
                }
            }
            return true
        }

        print("[ERROR] Invalid URL Scheme or Host in AppDelegate")
        return false
    }

    // MARK: - Setup Notification Observers
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("SpotifyLoginSuccess"),
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                print("[DEBUG] Spotify login successful! Navigating to ContentView.")
                self.isLoggedIn = true
                self.updateRootView()
                
                // Check for a Supabase session (optional in our custom flow)
                Task {
                    do {
                        let session = try await SupabaseService.shared.auth.session
                        print("[DEBUG] Supabase session active: \(session)")
                        UserDefaults.standard.set(session.accessToken, forKey: "SupabaseAccessToken")
                    } catch {
                        print("[WARNING] No active Supabase session found, skipping built-in OAuth because we use our custom token approach.")
                    }
                }
            }
        }

        NotificationCenter.default.addObserver(
            forName: Notification.Name("SpotifyLoginFailure"),
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                print("Spotify login failed. User needs to log in again.")
                self.isLoggedIn = false
                self.updateRootView()
            }
        }
    }
}
