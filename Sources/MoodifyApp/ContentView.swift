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
    @AppStorage("UserLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("UserCompletedQuestionnaire") private var hasCompletedQuestionnaire: Bool = false
    @AppStorage("SpotifyAccessToken") private var accessToken: String?

    @State private var responses: [String: String] = [:]
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var isSubmitted: Bool = false
    @State private var isCheckingToken: Bool = true
    @State private var navigateToQuestionnaire: Bool = false

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
                            SpotifyLoginView(isLoggedIn: $isLoggedIn, navigateToQuestionnaire: $navigateToQuestionnaire)
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
                }
      }

    // MARK: - Validate Spotify Session Before Loading UI
    private func validateUserSession() {
        print("🔍 Checking user session...")

        if let savedToken = UserDefaults.standard.string(forKey: "SpotifyAccessToken"),
           !savedToken.isEmpty,
           SpotifyAuthManager.shared.isTokenValid {

            print("✅ User has a valid Spotify token.")
            isLoggedIn = true
            navigateToQuestionnaire = true
            isCheckingToken = false
        } else {
            print("⚠️ Token expired or missing. Attempting refresh...")

            SpotifyAuthManager.shared.refreshAccessToken { success in
                DispatchQueue.main.async {
                    if success, let refreshedToken = UserDefaults.standard.string(forKey: "SpotifyAccessToken"), !refreshedToken.isEmpty {
                        print("✅ Token successfully refreshed.")
                        isLoggedIn = true
                        navigateToQuestionnaire = true
                    } else {
                        print("❌ Failed to refresh token. Redirecting to login.")
                        isLoggedIn = false
                    }
                    isCheckingToken = false
                }
            }
        }
    }


    // MARK: - Thank You View After Submission
    var thankYouView: some View {
        VStack {
            Text("✅ Thank you for submitting!")
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
                    questionView(question)
                }

                submitButton
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Individual Question View
    func questionView(_ question: String) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(question)
                .font(.headline)
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(answerOptions, id: \.self) { option in
                    answerButton(question: question, option: option)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Answer Button
    func answerButton(question: String, option: String) -> some View {
        Button(action: {
            responses[question] = option
            checkAndHideError()
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
            .background(responses[question] == option ? Color.blue.opacity(0.2) : Color(.systemGray6))
            .cornerRadius(10)
        }
    }

    // MARK: - Submit Button
    var submitButton: some View {
        Button(action: submitResponses) {
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

    // MARK: - Error View
    var errorView: some View {
        VStack {
            Text("⚠️ Please answer all questions.")
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
                .padding(.horizontal, 20)
            Spacer()
        }
        .transition(.opacity)
        .animation(.easeInOut, value: showError)
    }

    // MARK: - Progress Calculation
    private var progress: Double {
        return Double(responses.count) / Double(likertQuestions.count)
    }

    // MARK: - Form Validation
    private func validateResponses() -> Bool {
        return likertQuestions.allSatisfy { responses[$0] != nil }
    }

    // MARK: - Error Handling
    private func checkAndHideError() {
        if validateResponses() {
            withAnimation(.easeInOut) {
                showError = false
            }
        }
    }

    // MARK: - Submit Responses to Supabase
    private func submitResponses() {
        if !validateResponses() {
            showError = true
            return
        }

        isLoading = true

        let responseObjects: [Response] = likertQuestions.compactMap { question in
            if let response = responses[question], !response.isEmpty {
                return Response(question: question, answer: response)
            }
            return nil
        }

        SupabaseService.shared.submitResponses(responses: responseObjects) { success in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    isSubmitted = true
                    hasCompletedQuestionnaire = true
                } else {
                    showError = true
                }
            }
        }
    }
}
