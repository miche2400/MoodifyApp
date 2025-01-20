import SwiftUI
import Foundation
import Supabase

struct ContentView: View {
    @State private var responses: [String: String] = [:] // Store answers
    @State private var items: [SupabaseItem] = [] // Store Supabase data
    @State private var isLoading: Bool = false

    private let likertQuestions = [
        "I feel content and satisfied with my current situation.",
        "I am feeling a bit stressed or overwhelmed.",
        "I feel calm and peaceful.",
        "I am feeling energetic and ready to take on challenges.",
        "I feel a bit down or low-spirited."
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea() // Ensure the background fills the screen

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Moodify")
                            .font(.largeTitle)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top)

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
                    }
                    .padding()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Consistent navigation behavior
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
