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
    @State private var items: [SupabaseItem] = [] // Store Supabase data
    @State private var isLoading: Bool = false
    @State private var isButtonPressed: Bool = false // Track button press state
    @State private var showError: Bool = false // Track error state

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
                    .ignoresSafeArea(.all) // Ensure the background fills the screen

                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        Text("Moodify")
                            .font(.largeTitle)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)

                        ForEach(likertQuestions, id: \.self) { question in
                            VStack(alignment: .leading, spacing: 15) {
                                Text(question)
                                    .font(.headline)
                                    .padding(.horizontal, 20)

                                // Vertical Answer Options
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(answerOptions, id: \.self) { option in
                                        Button(action: {
                                            responses[question] = option
                                            checkAndHideError()
                                        }) {
                                            HStack {
                                                Circle()
                                                    .fill(responses[question] == option ? Color.blue : Color.gray)
                                                    .frame(width: 20, height: 20)
                                                Text(option)
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                            }
                                            .padding()
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        Button(action: {
                            if validateResponses() {
                                isButtonPressed = true
                                submitResponses()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    isButtonPressed = false
                                }
                            } else {
                                showError = true
                            }
                        }) {
                            Text("Submit")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isButtonPressed ? Color.blue.opacity(0.7) : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .scaleEffect(isButtonPressed ? 0.95 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isButtonPressed)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    .padding(.bottom, 40) // Add space at the bottom of the scroll view
                }

                // Error alert
                if showError {
                    VStack {
                        Text("Please answer all questions.")
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

    private func validateResponses() -> Bool {
        // Ensure all questions have been answered
        return likertQuestions.allSatisfy { question in
            responses[question] != nil
        }
    }

    private func checkAndHideError() {
        // Automatically hide the error when all questions are answered
        if validateResponses() {
            withAnimation {
                showError = false
            }
        }
    }

    private func submitResponses() {
        isLoading = true
        let responseObjects: [Response] = likertQuestions.compactMap { question in
            if let response = responses[question], !response.isEmpty {
                return Response(question: question, answer: response)
            } else {
                return nil
            }
        }

        guard !responseObjects.isEmpty else {
            isLoading = false
            return
        }

        SupabaseService.shared.submitResponses(responses: responseObjects) { success in
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
}
