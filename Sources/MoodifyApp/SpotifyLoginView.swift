//
//  SpotifyLoginView.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 27/01/2025.
//
import SwiftUI

struct SpotifyLoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var isAuthenticating: Bool = false // Track authentication state
    @State private var authenticationError: String? = nil // Track errors

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // App Logo
            Image("music logo design")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .accessibility(label: Text("App logo"))

            // App Title
            Text("Moodify - Your Emotional DJ")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .accessibility(label: Text("Moodify - Your Emotional DJ"))

            // Error Message (if any)
            if let error = authenticationError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .accessibility(label: Text("Authentication Error"))
            }

            // Spotify Login Button
            Button(action: authenticateWithSpotify) {
                if isAuthenticating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                } else {
                    Text("Login with Spotify")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                }
            }
            .disabled(isAuthenticating) // Disable button during authentication
            .accessibility(label: Text(isAuthenticating ? "Authenticating" : "Login with Spotify"))

            Spacer()
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea()
        .onAppear {
            authenticationError = nil // Reset error on screen load
        }
    }

    private func authenticateWithSpotify() {
        isAuthenticating = true
        authenticationError = nil

        SpotifyAuthManager.shared.authenticate { success in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success {
                    isLoggedIn = true // Set logged-in state to true
                } else {
                    authenticationError = "Authentication failed. Please try again."
                }
            }
        }
    }
}
