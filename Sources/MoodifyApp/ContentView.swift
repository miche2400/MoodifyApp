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
    @State private var errorMessage: String?

    private let likertQuestions = [
        "I feel content and satisfied with my current situation.",
        "I am feeling a bit stressed or overwhelmed.",
        "I feel calm and peaceful.",
        "I am feeling energetic and ready to take on challenges.",
        "I feel a bit down or low-spirited."
    ]

    var body: some View {
        ScrollView {
            VStack {
                Text("Moodify")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                if isLoading {
                    ProgressView()
                } else {
                    formView
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                Button("Test Supabase Connection") {
                    testSupabaseConnection()
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle("Moodify")
        .onAppear {
            fetchItems()
        }
    }

    private var formView: some View {
        VStack(spacing: 20) {
            ForEach(likertQuestions, id: \ .self) { question in
                VStack(alignment: .leading) {
                    Text(question)
                        .font(.headline)
                    Picker("Response", selection: $responses[question]) {
                        Text("Strongly Disagree").tag("Strongly Disagree")
                        Text("Disagree").tag("Disagree")
                        Text("Neutral").tag("Neutral")
                        Text("Agree").tag("Agree")
                        Text("Strongly Agree").tag("Strongly Agree")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding()
            }
            Button("Submit") {
                submitResponses()
            }
            .padding()
        }
    }

    private func submitResponses() {
        isLoading = true
        let responseObjects: [Response] = likertQuestions.compactMap { question in
            if let response = responses[question], !response.isEmpty {
                return Response(
                    question: question,
                    answer: response
                )
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
                if success {
                    print("Responses submitted successfully!")
                } else {
                    errorMessage = "Failed to submit responses."
                }
            }
        }
    }

    private func fetchItems() {
        isLoading = true
        SupabaseService.shared.fetchResponses { fetchedItems in
            DispatchQueue.main.async {
                isLoading = false
                self.items = fetchedItems
                if fetchedItems.isEmpty {
                    errorMessage = "No data fetched."
                }
            }
        }
    }

    private func testSupabaseConnection() {
        let testResponse = Response(question: "Test Question", answer: "Test Answer")
        SupabaseService.shared.submitResponses(responses: [testResponse]) { success in
            if success {
                print("✅ Supabase Connection Successful!")
            } else {
                print("❌ Supabase Connection Failed!")
            }
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    return formatter
}()

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
