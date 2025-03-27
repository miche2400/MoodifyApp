//
//  QuestionnaireView.swift
//  Moodify
//
//  Created by Michelle Rodriguez on 24/03/2025.
//

import SwiftUI

struct QuestionnaireView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var responses: [String: String] = [:]
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Playful and modern Likert questions for determining current mood
    let likertQuestions = [
        "I'm totally on fire today – ready to crush my goals!",
        "I'm super chill and living in my zen zone right now.",
        "I'm in a deep reflective mood, thinking about life's twists.",
        "I'm feeling uncomfortable and a bit anxious today.",
        "I'm over-the-moon joyful, buzzing with positive vibes!"
    ]
    
    let answerOptions = ["Strongly Disagree", "Disagree", "Neutral", "Agree", "Strongly Agree"]
    let onComplete: (String) -> Void

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 32) {
                    // Updated modern title with gradient overlay and shadow
                    Text("What’s Your Vibe Today?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                    
                    ForEach(likertQuestions, id: \.self) { question in
                        QuestionView(question: question, answerOptions: answerOptions, responses: $responses)
                            .padding(.horizontal)
                    }
                    
                    submitButton
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    struct QuestionView: View {
        let question: String
        let answerOptions: [String]
        @Binding var responses: [String: String]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(question)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(12)
                VStack(spacing: 12) {
                    ForEach(answerOptions, id: \.self) { option in
                        Button(action: {
                            responses[question] = option
                        }) {
                            HStack {
                                Circle()
                                    .fill(responses[question] == option ? Color.white.opacity(0.9) : Color.gray.opacity(0.5))
                                    .frame(width: 20, height: 20)
                                Text(option)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding()
                            .background(responses[question] == option ? Color.white.opacity(0.2) : Color.clear)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                .background(Color.black.opacity(0.25))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 6)
            }
            .padding(.vertical, 8)
        }
    }
    
    var submitButton: some View {
        Button(action: mainSubmitFlow) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                        .padding(.trailing, 8)
                }
                Text("Submit")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                validateResponses() ?
                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                                   startPoint: .leading,
                                   endPoint: .trailing)
                :
                    LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray]),
                                   startPoint: .leading,
                                   endPoint: .trailing)
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 6)
        }
        .disabled(isLoading || !validateResponses())
    }
    
    private func validateResponses() -> Bool {
        likertQuestions.allSatisfy { responses[$0] != nil && !responses[$0]!.isEmpty }
    }
    
    private func mainSubmitFlow() {
        isLoading = true
        let formattedResponses = responses.map { Response(question: $0.key, answer: $0.value) }
        
        SupabaseService.shared.submitResponses(responses: formattedResponses) { success in
            if success {
                OpenAIService.shared.generatePlaylist(from: formattedResponses) { result in
                    DispatchQueue.main.async {
                        isLoading = false
                        switch result {
                        case .success(let playlistID):
                            onComplete(playlistID)
                            dismiss()
                        case .failure:
                            showError = true
                            errorMessage = "Failed to generate playlist. Please try again."
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    isLoading = false
                    showError = true
                    errorMessage = "Failed to submit responses to Supabase."
                }
            }
        }
    }
}
