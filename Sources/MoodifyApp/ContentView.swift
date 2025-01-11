//  ContentView.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 17/12/2024.
//
import SwiftUI
import Foundation
import Supabase

struct ContentView: View {
    @State private var responses: [String: Int] = [:] // Store Likert scale responses
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
            VStack {
                if isLoading {
                    ProgressView()
                } else {
                    formView
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                Button("Test Supabase Connection") {
                    testSupabaseConnection()
                }
                .padding()
            }
            .navigationTitle("Moodify")
            .onAppear {
                fetchItems()
            }
        }
    }

    private var formView: some View {
        Form {
            ForEach(likertQuestions, id: \ .self) { question in
                Section(header: Text(question)) {
                    Picker("Response", selection: $responses[question]) {
                        Text("Strongly Disagree").tag(1)
                        Text("Disagree").tag(2)
                        Text("Neutral").tag(3)
                        Text("Agree").tag(4)
                        Text("Strongly Agree").tag(5)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            Button("Submit") {
                submitResponses()
            }
            .padding()
        }
        .listStyle(GroupedListStyle())
    }

    private func submitResponses() {
        isLoading = true
        let responseObjects: [Response] = likertQuestions.compactMap { question in
            if let response = responses[question], response > 0 {
                return Response(
                    likert_scale: response,
                    multiple_choice: "Default Choice",
                    timestamp: ISO8601DateFormatter().string(from: Date())
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
        let testResponse = Response(likert_scale: 3, multiple_choice: "Test Choice", timestamp: ISO8601DateFormatter().string(from: Date()))
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
