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
    // Use this flag to force showing the questionnaire
    let forceQuestionnaire: Bool 

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
    @State private var playlistID: String? // Final playlist ID from OpenAI

    // If the user has at least one playlist, this becomes true
    @State private var userHasPlaylists: Bool = false

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
                    ProgressView("Checking session...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.5)
                } else {
                    if isLoggedIn {
                        // If forceQuestionnaire is true, show the questionnaire even if playlists exist.
                        // Otherwise, if the user already has stored playlists, show AllPlaylistsView.
                        if forceQuestionnaire {
                            questionnaireView
                        } else {
                            if userHasPlaylists {
                                AllPlaylistsView()
                            } else {
                                questionnaireView
                            }
                        }
                    } else {
                        SpotifyLoginView(
                            isLoggedIn: .constant(false),
                            navigateToQuestionnaire: .constant(false)
                        )
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToQuestionnaire) {
                questionnaireView
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
                // Only check stored playlists if we're not forcing the questionnaire.
                if !forceQuestionnaire {
                    checkStoredPlaylists()
                }
            }
        }
        .onChange(of: isLoggedIn, initial: false) { oldValue, newValue in
            if !oldValue && newValue {
                print("[DEBUG] User logged in.")
                // Once logged in, check if the user has stored playlists (if not forcing questionnaire)
                if !forceQuestionnaire {
                    checkStoredPlaylists()
                }
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
    
    // MARK: - Check if User Has Stored Playlists
    private func checkStoredPlaylists() {
        SupabaseService.shared.fetchMoodSelections { fetched in
            DispatchQueue.main.async {
                if fetched.isEmpty {
                    print("[DEBUG] No playlists found for current user.")
                    self.userHasPlaylists = false
                } else {
                    print("[DEBUG] Playlists found for current user.")
                    self.userHasPlaylists = true
                }
            }
        }
    }

    // MARK: - Questionnaire View
    var questionnaireView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                Text("Moodify")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 30)

                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding(.horizontal, 20)

                ForEach(likertQuestions, id: \.self) { question in
                    questionCardView(question)
                }

                submitButton
            }
            .padding(.bottom, 40)
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

    // MARK: - Submit Questionnaire
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
                                // Navigate to the playlist recommendation view
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
