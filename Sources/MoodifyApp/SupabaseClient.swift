//
//  SupabaseClient.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 17/12/2024.
//
import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()

    private let client: SupabaseClient

    private init() {
        let supabaseURL = URL(string: "https://djmpjkmbodnteepykdva.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqbXBqa21ib2RudGVlcHlrZHZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE1MjExODcsImV4cCI6MjA0NzA5NzE4N30.7ftI6sivTBcM21M9Seq68AhCEyVRzouq_7OIDRoeZoI"  // Replace with your Supabase API key
        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }

    // MARK: - Submit Responses
    func submitResponses(responses: [Response], completion: @escaping (Bool) -> Void) {
        Task {
            do {
                let response = try await client
                    .database
                    .from("responses")
                    .insert(values: responses)
                    .execute()

                if response.status == 200 {
                    print("Data inserted successfully.")
                    completion(true)
                } else {
                    print("Error inserting data: \(response.status)")
                    completion(false)
                }
            } catch {
                print("Error inserting data: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    func fetchResponses(completion: @escaping ([SupabaseItem]) -> Void) {
        Task {
            do {
                // Fetch and decode responses directly into the SupabaseItem array
                let items: [SupabaseItem] = try await client
                    .database
                    .from("responses")
                    .select()
                    .execute()
                    .value // Automatically decodes into [SupabaseItem]

                print("Fetched items: \(items)") // Log the fetched items for debugging
                completion(items)
            } catch {
                print("Error fetching data: \(error.localizedDescription)")
                completion([]) // Return an empty array in case of error
            }
        }
    }

}

