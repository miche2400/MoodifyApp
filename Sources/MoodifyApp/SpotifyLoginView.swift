//
//  SpotifyLoginView.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 27/01/2025.
//

import SwiftUI

struct SpotifyLoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var isAuthenticating: Bool = false
    @State private var authenticationError: String?
    @State private var isCheckingToken: Bool = true // Prevents UI flickering while checking token
    @State private var hasTriedLogin: Bool = false // Tracks if login attempt has occurred

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // App Title
            Text("Moodify - Your Emotional DJ")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .foregroundColor(.primary)
                .accessibility(label: Text("Moodify - Your Emotional DJ"))

            // Display Error Message (Only after login attempt)
            if hasTriedLogin, let error = authenticationError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                    .accessibility(label: Text("Authentication Error: \(error)"))
            }

            // Spotify Login Button (Only shows if token check is completed)
            if !isCheckingToken {
                Button(action: authenticateWithSpotify) {
                    HStack {
                        if isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isAuthenticating ? "Logging in..." : "Login with Spotify")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isAuthenticating ? Color.gray : Color.green)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
                    .animation(.easeInOut, value: isAuthenticating)
                }
                .disabled(isAuthenticating)
                .accessibility(label: Text(isAuthenticating ? "Logging in to Spotify" : "Login with Spotify"))
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
            }

            Spacer()

            // App Version Info
            Text("Version 1.0")
                .font(.footnote)
                .foregroundColor(.gray)
                .accessibility(label: Text("App version 1.0"))
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            checkIfAlreadyLoggedIn()
            setupLoginListeners()
        }
    }

    // MARK: - Spotify Authentication Flow
    private func authenticateWithSpotify() {
        isAuthenticating = true
        authenticationError = nil
        hasTriedLogin = true // Mark that a login attempt has started

        print("⏳ Starting Spotify authentication...")

        SpotifyAuthManager.shared.authenticate { success in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success {
                    print("✅ Authentication successful. Redirecting to app...")
                    checkLoginStatus()
                } else {
                    print("❌ Authentication failed.")
                    authenticationError = "Authentication failed. Please try again."
                }
            }
        }
    }

    // MARK: - Check If User Is Already Logged In
    private func checkIfAlreadyLoggedIn() {
        print("🔄 Checking if user is already logged in...")

        // Check if access token exists & is still valid
        if SpotifyAuthManager.shared.isTokenValid {
            print("✅ User has a valid access token. Redirecting...")
            isLoggedIn = true
            return
        }

        print("⚠️ No valid access token found. Checking if refresh token exists...")

        SpotifyAuthManager.shared.refreshAccessToken { success in
            DispatchQueue.main.async {
                isCheckingToken = false // Hide loading state

                if success {
                    print("✅ Access token refreshed successfully. Redirecting...")
                    isLoggedIn = true
                } else {
                    print("⚠️ No valid token found. User must log in.")
                    authenticationError = "Failed to retrieve token. Try logging in again."
                }
            }
        }
    }

    // MARK: - Ensure Token is Valid Before Proceeding
    private func checkLoginStatus() {
        if SpotifyAuthManager.shared.isTokenValid {
            print("✅ Token is valid, logging in.")
            isLoggedIn = true
        } else {
            print("❌ Token validation failed.")
            authenticationError = "Failed to retrieve token. Try again."
        }
    }

    // MARK: - Listen for Authentication Success
    private func setupLoginListeners() {
        NotificationCenter.default.addObserver(forName: Notification.Name("SpotifyLoginSuccess"), object: nil, queue: .main) { _ in
            DispatchQueue.main.async {
                print("🎵 Login Success Notification Received. Redirecting user...")
                isLoggedIn = true
            }
        }

        NotificationCenter.default.addObserver(forName: Notification.Name("SpotifyLoginFailure"), object: nil, queue: .main) { _ in
            DispatchQueue.main.async {
                print("⚠️ Login Failure Notification Received.")
                authenticationError = "Login failed. Please try again."
            }
        }
    }
}
