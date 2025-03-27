//
//  ContentView.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 17/12/2024.
//

import SwiftUI
import Foundation
import Supabase

struct ContentView: View {
    // MARK: - App Storage
    @AppStorage("UserLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("SpotifyAccessToken") private var accessToken: String?

    // MARK: - State Variables
    @State private var responses: [String: String] = [:]
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String?
    @State private var isSubmitted: Bool = false
    @State private var isCheckingToken: Bool = true

    // Controls navigation
    @State private var navigateToQuestionnaire: Bool = false
    @State private var navigateToPlaylist: Bool = false
    @State private var playlistID: String? // Set after generating a playlist

    // If the user has at least one playlist, skip the questionnaire
    @State private var userHasPlaylists = false

    // MARK: - Questionnaire Data
    private let likertQuestions = [
        "I feel content and satisfied with my current situation.",
        "I am feeling a bit stressed or overwhelmed.",
        "I feel calm and peaceful.",
        "I am feeling energetic and ready to take on challenges.",
        "I feel a bit down or low-spirited."
    ]
    
    private let answerOptions = [
        "Strongly Disagree",
        "Disagree",
        "Neutral",
        "Agree",
        "Strongly Agree"
    ]

    // MARK: - Progress Calculation
    private var progress: Double {
        Double(responses.count) / Double(likertQuestions.count)
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                if isCheckingToken {
                    // Checking if user is logged in
                    ProgressView("Checking session...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.5)
                } else {
                    if isLoggedIn {
                        // If user is logged in, decide which screen to show:
                        // If userHasPlaylists == true, show AllPlaylistsView
                        // Otherwise, show the questionnaire
                        if userHasPlaylists {
                            AllPlaylistsView()
                        } else {
                            
                            QuestionnaireView { playlistID in
                                self.playlistID = playlistID
                                self.navigateToPlaylist = true
                            }

                        }
                    } else {
                        // Not logged in => show Spotify login
                        SpotifyLoginView(
                            isLoggedIn: .constant(false),
                            navigateToQuestionnaire: .constant(false)
                        )
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToQuestionnaire) {
                QuestionnaireView { playlistID in
                    self.playlistID = playlistID
                    self.navigateToPlaylist = true
                }

            }
            .navigationDestination(isPresented: $navigateToPlaylist) {
                if let playlistID = playlistID {
                    PlaylistRecommendationView(playlistID: playlistID)
                } else {
                    Text("Failed to load playlist.")
                }
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "Something went wrong."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                print("[DEBUG] ContentView appeared. Checking user session...")
                validateUserSession()
            }
        }
        .onChange(of: isLoggedIn, initial: false) { oldValue, newValue in
            // If user logs in, check if they already have playlists
            if !oldValue && newValue {
                print("[DEBUG] User logged in. Checking if user has playlists.")
                checkStoredPlaylists()
            }
        }
    }

    // MARK: - Validate Spotify Session
    private func validateUserSession() {
        print("[DEBUG] Starting session validation...")

        if let token = SpotifyAuthManager.shared.getAccessToken(), !token.isEmpty {
            print("[DEBUG] Found existing Spotify token.")

            Task {
                let success = await SupabaseService.shared.loginWithSpotify(token: token)
                DispatchQueue.main.async {
                    self.isCheckingToken = false
                    self.isLoggedIn = success
                }
            }
        } else {
            print("[DEBUG] No valid Spotify token found. Showing login screen.")
            DispatchQueue.main.async {
                self.isCheckingToken = false
                self.isLoggedIn = false
            }
        }
    }
    
    // MARK: - Check if user has any playlists
    private func checkStoredPlaylists() {
        SupabaseService.shared.fetchMoodSelections { fetched in
            DispatchQueue.main.async {
                self.isCheckingToken = false
                if fetched.isEmpty {
                    print("[DEBUG] No playlists found for current user => show questionnaire.")
                    self.userHasPlaylists = false
                } else {
                    print("[DEBUG] Playlists found => show AllPlaylistsView.")
                    self.userHasPlaylists = true
                }
            }
        }
    }

    // MARK: - Question Card View
    func questionCardView(_ question: String) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(question)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
                .padding(.top, 15)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(answerOptions, id: \.self) { option in
                    answerSelectionButton(question: question, option: option)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 15)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal, 15)
        .animation(.easeInOut, value: responses)
    }

    // MARK: - Answer Selection Button
    func answerSelectionButton(question: String, option: String) -> some View {
        Button(action: {
            responses[question] = option
        }) {
            HStack {
                Circle()
                    .fill(responses[question] == option ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 20, height: 20)
                Text(option)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(
                responses[question] == option ? Color.blue.opacity(0.2) : Color.clear
            )
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Submit Button
    var submitButton: some View {
        Button(action: mainSubmitFlow) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                } else {
                    Text(isSubmitted ? "Submitted!" : "Submit")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSubmitted ? Color.green : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(isLoading ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .disabled(isLoading || isSubmitted || !validateResponses())
    }

    private func validateResponses() -> Bool {
        likertQuestions.allSatisfy { responses[$0] != nil && !responses[$0]!.isEmpty }
    }

    private func mainSubmitFlow() {
        guard validateResponses() else {
            showError = true
            errorMessage = "Please answer all questions before submitting."
            return
        }

        isLoading = true
        let formattedResponses = responses.map { Response(question: $0.key, answer: $0.value) }

        print("[DEBUG] Submitting responses to Supabase...")

        SupabaseService.shared.submitResponses(responses: formattedResponses) { success in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    print("[DEBUG] Responses stored successfully.")
                    self.isSubmitted = true

                    print("[DEBUG] Generating playlist with OpenAI...")
                    OpenAIService.shared.generatePlaylist(from: formattedResponses) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let generatedPlaylistID):
                                print("[DEBUG] Playlist generated successfully: \(generatedPlaylistID)")
                                self.playlistID = generatedPlaylistID  // Store playlist ID
                                self.navigateToPlaylist = true
                            case .failure(let error):
                                print("[ERROR] Failed to generate playlist: \(error.localizedDescription)")
                                self.showError = true
                                self.errorMessage = "Failed to generate playlist. Please try again."
                            }
                        }
                    }
                } else {
                    self.showError = true
                    self.errorMessage = "Failed to submit responses to Supabase."
                }
            }
        }
    }
}

