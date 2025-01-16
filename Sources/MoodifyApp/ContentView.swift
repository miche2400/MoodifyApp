import SwiftUI
import Foundation
import Supabase

struct ContentView: View {
    @State private var responses: [String: String] = [:] // Store answers
    @State private var items: [SupabaseItem] = [] // Store Supabase data
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    private let likertQuestions = [
        "I feel content and satisfied with my current situation.",
        "I am feeling a bit stressed or overwhelmed.",
        "I feel calm and peaceful.",
        "I am feeling energetic and ready to take on challenges.",
        "I feel a bit down or low-spirited."
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Moodify")
                        .font(.largeTitle)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .center)

                    ForEach(likertQuestions, id: \.self) { question in
                        VStack(alignment: .leading) {
                            Text(question)
                                .font(.headline)
                                .padding(.bottom, 5)

                            Picker("Response", selection: $responses[question]) {
                                Text("Strongly Disagree").tag("Strongly Disagree")
                                Text("Disagree").tag("Disagree")
                                Text("Neutral").tag("Neutral")
                                Text("Agree").tag("Agree")
                                Text("Strongly Agree").tag("Strongly Agree")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.bottom)
                        }
                    }

                    Button("Submit") {
                        submitResponses()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all) // This will ignore safe area and fill the entire screen
            .background(Color(.systemBackground))
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Full screen behavior for all devices
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
            errorMessage = "Please complete all questions before submitting."
            return
        }

        SupabaseService.shared.submitResponses(responses: responseObjects) { success in
            DispatchQueue.main.async {
                isLoading = false
                errorMessage = success ? "✅ Responses submitted successfully!" : "❌ Failed to submit responses."
            }
        }
    }
}
