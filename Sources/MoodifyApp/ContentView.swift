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
    @State private var responses: [String: String] = [:] // Store answers
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var isSubmitted: Bool = false // Track submission status
    @AppStorage("UserCompletedQuestionnaire") private var hasCompletedQuestionnaire: Bool = false // Persistent flag

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
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                if hasCompletedQuestionnaire {
                    // Redirect user to main content after submission
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
                } else {
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
                                VStack(alignment: .leading, spacing: 15) {
                                    Text(question)
                                        .font(.headline)
                                        .padding(.horizontal, 20)

                                    VStack(alignment: .leading, spacing: 10) {
                                        ForEach(answerOptions, id: \.self) { option in
                                            Button(action: {
                                                responses[question] = option
                                                checkAndHideError()
                                                print("✅ Selected answer for '\(question)': \(option)")
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
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }

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
                            .disabled(isLoading || isSubmitted) // Prevent multiple taps
                        }
                        .padding(.bottom, 40)
                    }
                }

                if showError {
                    VStack {
                        Text("⚠️ Please answer all questions.")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                        Spacer()
                    }
                    .animation(.easeInOut, value: showError)
                    .transition(.opacity)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Progress Calculation
    private var progress: Double {
        return Double(responses.count) / Double(likertQuestions.count)
    }

    // MARK: - Form Validation
    private func validateResponses() -> Bool {
        return likertQuestions.allSatisfy { responses[$0] != nil }
    }

    private func checkAndHideError() {
        if validateResponses() {
            withAnimation {
                showError = false
            }
        }
    }

    // MARK: - Submission Handling
    private func submitResponses() {
        if !validateResponses() {
            print("❌ Error: Not all questions are answered.")
            showError = true
            return
        }

        isLoading = true
        print("⏳ Submitting questionnaire responses...")

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
                    hasCompletedQuestionnaire = true // ✅ Store completion status
                    print("✅ Responses successfully submitted to Supabase.")
                } else {
                    showError = true
                    print("❌ Error submitting responses.")
                }
            }
        }
    }
}
