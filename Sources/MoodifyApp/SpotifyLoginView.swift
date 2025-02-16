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

            Spacer()

            Text("Version 1.0")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            checkExistingSession()
            setupLoginListeners()
        }
        .onDisappear {
            removeLoginListeners()
        }
    }

    // MARK: - Check Existing Session on App Launch
    private func checkExistingSession() {
        if SpotifyAuthManager.shared.isTokenValid {
            print("✅ User already logged in with a valid token.")
            isLoggedIn = true
            navigateToQuestionnaire = true
        } else {
            print("🔄 No valid session found. User needs to log in.")
            isLoggedIn = false
        }
    }

    // MARK: - Spotify Authentication Flow
    private func authenticateWithSpotify() {
        isAuthenticating = true
        authenticationError = nil
        hasTriedLogin = true

        SpotifyAuthManager.shared.authenticate { success in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success {
                    print("✅ Authentication initiated. Waiting for token exchange...")
                } else {
                    print("❌ Authentication failed.")
                    authenticationError = "Authentication failed. Please try again."
                }
            }
        }
    }

    // MARK: - Listen for Authentication Success and Navigate to Questionnaire
    private func setupLoginListeners() {
        NotificationCenter.default.addObserver(forName: AppDelegate.spotifyLoginSuccessNotification, object: nil, queue: .main) { _ in
            DispatchQueue.main.async {
                print("🎵 Login Success! Validating token...")
                validateTokenAfterLogin()
            }
        }

        NotificationCenter.default.addObserver(forName: AppDelegate.spotifyLoginFailureNotification, object: nil, queue: .main) { _ in
            DispatchQueue.main.async {
                print("❌ Login Failed. Resetting authentication state.")
                authenticationError = "Login failed. Please try again."
                isLoggedIn = false
            }
        }
    }

    // MARK: - Validate Token After Login
    private func validateTokenAfterLogin() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Delay to ensure the token is stored
            print("🔍 Checking token after login...")

            if SpotifyAuthManager.shared.isTokenValid {
                print("✅ Token is valid. Navigating to questionnaire.")
                isLoggedIn = true
                navigateToQuestionnaire = true
            } else {
                print("⚠️ Token invalid after login. Trying to refresh...")

                SpotifyAuthManager.shared.refreshAccessToken { success in
                    DispatchQueue.main.async {
                        if success {
                            print("✅ Token refreshed successfully. Navigating to questionnaire.")
                            isLoggedIn = true
                            navigateToQuestionnaire = true
                        } else {
                            print("❌ Token validation failed after login.")
                            authenticationError = "Failed to retrieve token. Please log in again."
                            isLoggedIn = false
                        }
                    }
                }
            }
        }
    }

    // MARK: - Remove Login Listeners on Disappear
    private func removeLoginListeners() {
        NotificationCenter.default.removeObserver(self, name: AppDelegate.spotifyLoginSuccessNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AppDelegate.spotifyLoginFailureNotification, object: nil)
    }
}
