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
    @AppStorage("UserCompletedQuestionnaire") private var hasCompletedQuestionnaire: Bool = false
    @AppStorage("SpotifyAccessToken") private var accessToken: String?

    // MARK: - State Variables
    @State private var responses: [String: String] = [:]
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String?
    @State private var isSubmitted: Bool = false
    @State private var isCheckingToken: Bool = true
    @State private var navigateToQuestionnaire: Bool = false
    @State private var navigateToPlaylist = false

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
                    ProgressView("Checking login status...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.5)
                        .onAppear {
                            validateUserSession()
                        }
                } else if !isLoggedIn {
                    SpotifyLoginView(
                        isLoggedIn: $isLoggedIn,
                        navigateToQuestionnaire: $navigateToQuestionnaire
                    )
                } else {
                    if hasCompletedQuestionnaire {
                        thankYouView
                    } else {
                        questionnaireView
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToQuestionnaire) {
                questionnaireView
            }
            .navigationDestination(isPresented: $navigateToPlaylist) {
                PlaylistRecommendationView(userResponses: responses.map { Response(question: $0.key, answer: $0.value) })
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "Something went wrong."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onChange(of: isLoggedIn) {
            if isLoggedIn {
                print("[DEBUG] User is logged in. Navigating to questionnaire.")
                navigateToQuestionnaire = true
            }
        }
    }

    // MARK: - Validate Spotify Session
    private func validateUserSession() {
        print("Checking user session...")

        if let token = SpotifyAuthManager.shared.getAccessToken(), !token.isEmpty {
            print("User is already logged in. Valid token found.")
            isLoggedIn = true
            isCheckingToken = false
            navigateToQuestionnaire = true
        } else {
            print("No valid token found. Trying to refresh...")
            SpotifyAuthManager.shared.refreshAccessToken { success in
                DispatchQueue.main.async {
                    if success {
                        print("Token refreshed successfully!")
                        self.isLoggedIn = true
                        self.navigateToQuestionnaire = true
                    } else {
                        print("Token refresh failed. Showing login screen.")
                        self.isLoggedIn = false
                    }
                    self.isCheckingToken = false
                }
            }
        }
    }

    // MARK: - Thank You View
    var thankYouView: some View {
        VStack {
            Text("Thank you for submitting!")
                .font(.title)
                .padding()
            Text("We are personalizing your experience.")
                .font(.headline)
                .padding(.bottom, 20)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
        }
        .transition(.opacity)
    }

    // MARK: - Modern Questionnaire View
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
    // MARK: - Validate Responses
    private func validateResponses() -> Bool {
        return likertQuestions.allSatisfy { responses[$0] != nil && !responses[$0]!.isEmpty }
    }
    // MARK: - Submit Responses to Supabase
    private func mainSubmitFlow() {
        guard validateResponses() else {
            showError = true
            errorMessage = "Please answer all questions before submitting."
            return
        }

        isLoading = true

        SupabaseService.shared.submitResponses(responses: responses.map { Response(question: $0.key, answer: $0.value) }) { success in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    self.isSubmitted = true
                    self.hasCompletedQuestionnaire = true
                    self.navigateToPlaylist = true
                } else {
                    self.showError = true
                    self.errorMessage = "Failed to submit responses to Supabase."
                }
            }
        }
    }
}
