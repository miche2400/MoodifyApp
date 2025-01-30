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

            // Display Error Message (if any)
            if let error = authenticationError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                    .accessibility(label: Text("Authentication Error: \(error)"))
            }

            // Spotify Login Button (Shows only if token check is completed)
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
            SpotifyAuthManager.shared.refreshTokenIfNeeded { success in
                DispatchQueue.main.async {
                    if success {
                        print("✅ User already logged in. Redirecting...")
                        isLoggedIn = true
                    } else {
                        isCheckingToken = false
                    }
                }
            }
        }

    }

    // MARK: - Spotify Authentication Flow
    private func authenticateWithSpotify() {
        isAuthenticating = true
        authenticationError = nil

        SpotifyAuthManager.shared.authenticate { success in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success {
                    isLoggedIn = true
                } else {
                    authenticationError = "Authentication failed. Please try again."
                }
            }
        }
    }

    // MARK: - Check If User Is Already Logged In
    private func checkIfAlreadyLoggedIn() {
        SpotifyAuthManager.shared.refreshTokenIfNeeded { success in
            DispatchQueue.main.async {
                isCheckingToken = false // Hide loading state

                if success {
                    isLoggedIn = true
                }
            }
        }
    }
}
