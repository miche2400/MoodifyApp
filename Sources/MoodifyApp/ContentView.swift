//
//  ContentView.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 17/12/2024.


import SwiftUI
import Foundation
import Supabase

struct ContentView: View {
    @State private var responses: [String: Int] = [:] // Store Likert scale responses
    @State private var items: [SupabaseItem] = [] // Store Supabase data

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
                Form {
                    ForEach(likertQuestions, id: \.self) { question in
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
                }
                Button("Submit Responses") {
                    submitResponses()
                }
                .padding()

                List {
                    ForEach(items, id: \.id) { item in
                        if let date = dateFormatter.date(from: item.timestamp) {
                            Text("Likert Scale: \(item.likert_scale), Timestamp: \(date, formatter: itemFormatter)")
                        } else {
                            Text("Likert Scale: \(item.likert_scale), Timestamp: Invalid date format")
                        }
                    }
                }
                .onAppear {
                    fetchItems()
                }
            }
            .navigationTitle("Moodify - Questionnaire")
        }
    }

    private func submitResponses() {
        // Convert responses into Response objects directly
        let responseObjects = likertQuestions.map { question in
            Response(
                likert_scale: responses[question] ?? 0,
                multiple_choice: "Default Choice",
                timestamp: ISO8601DateFormatter().string(from: Date()) // Use ISO 8601 format for timestamp
            )
        }

        // Send responses to Supabase
        SupabaseService.shared.submitResponses(responses: responseObjects) { success in
            if success {
                print("Responses submitted successfully!")
            } else {
                print("Failed to submit responses.")
            }
        }
    }

    private func fetchItems() {
        SupabaseService.shared.fetchResponses { fetchedItems in
            DispatchQueue.main.async {
                self.items = fetchedItems
            }
        }
    }
}

// Date formatter for parsing the database timestamp strings
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ" // Adjust this format if necessary
    return formatter
}()

// Date formatter for displaying parsed dates in a user-friendly format
private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
