//
//  SpotifyLoginView.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 27/01/2025.
//

import SwiftUI

struct SpotifyLoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var navigateToQuestionnaire: Bool
    @State private var isAuthenticating: Bool = false
    @State private var authenticationError: String?
    @State private var hasTriedLogin: Bool = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("Moodify - Your Emotional DJ")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .foregroundColor(.primary)

            if hasTriedLogin, let error = authenticationError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
            }

            // Login Button - Ensures user must tap manually
            Button(action: {
                authenticateWithSpotify()
            }) {
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

            Spacer()

            Text("Version 1.0")
                .font(.footnote)
                .foregroundColor(.gray)

        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            setupLoginListeners()
        }
        .onDisappear {
            removeLoginListeners()
        }
    }

    // MARK: - Spotify Authentication Flow (Only triggered by button!)
    private func authenticateWithSpotify() {
        print("User tapped login button. Starting authentication...")
        guard !isAuthenticating else { return } // Prevent multiple login attempts
        isAuthenticating = true
        authenticationError = nil
        hasTriedLogin = true

        SpotifyAuthManager.shared.authenticate { success in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success {
                    print("Authentication initiated. Waiting for token exchange...")
                } else {
                    print("Authentication failed.")
                    authenticationError = "Authentication failed. Please try again."
                }
            }
        }
    }

    // MARK: - Listen for Authentication Success and Validate Token
    private func setupLoginListeners() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("SpotifyLoginSuccess"),
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                print("[DEBUG] Received SpotifyLoginSuccess notification in SpotifyLoginView!")
                validateTokenAfterLogin()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("SpotifyLoginFailure"),
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                print("[ERROR] Received SpotifyLoginFailure notification")
                authenticationError = "Login failed. Please try again."
                isLoggedIn = false
            }
        }
    }

    // MARK: - Validate Token After Login
    private func validateTokenAfterLogin() {
        print("Checking token after login...")

        if let token = SpotifyAuthManager.shared.getAccessToken(), !token.isEmpty {
            print("Token is valid. Navigating to questionnaire.")
            isLoggedIn = true
            navigateToQuestionnaire = true
        } else {
            print("Token invalid after login. Attempting refresh...")

            SpotifyAuthManager.shared.refreshAccessToken { success in
                DispatchQueue.main.async {
                    if success {
                        print("Token refreshed successfully. Navigating to questionnaire.")
                        isLoggedIn = true
                        navigateToQuestionnaire = true
                    } else {
                        print("Token validation failed after login.")
                        authenticationError = "Failed to retrieve token. Please log in again."
                        isLoggedIn = false
                    }
                }
            }
        }
    }

    // MARK: - Remove Login Listeners on Disappear
    private func removeLoginListeners() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("SpotifyLoginSuccess"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("SpotifyLoginFailure"), object: nil)
    }
}

