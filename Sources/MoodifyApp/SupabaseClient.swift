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
        // Replace these values with your actual Supabase URL and API key
        let supabaseURL = URL(string: "https://djmpjkmbodnteepykdva.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqbXBqa21ib2RudGVlcHlrZHZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE1MjExODcsImV4cCI6MjA0NzA5NzE4N30.7ftI6sivTBcM21M9Seq68AhCEyVRzouq_7OIDRoeZoI"
        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }

    // MARK: - Submit Responses
    func submitResponses(responses: [Response], completion: @escaping (Bool) -> Void) {
        Task {
            do {
                // Execute the insertion query
                let result = try await client
                    .from("responses")
                    .insert(responses)
                    .execute()

                // Check the status code to determine the outcome
                if result.status == 201 { // 201 indicates successful insertion
                    print("Data inserted successfully.")
                    completion(true)
                } else {
                    // Optionally handle different statuses if needed
                    print("Insertion failed with status: \(result.status)")
                    completion(false)
                }
            } catch {
                print("Error during data insertion: \(error.localizedDescription)")
                completion(false)
            }
        }
    }


    // MARK: - Fetch Responses
    func fetchResponses(completion: @escaping ([SupabaseItem]) -> Void) {
        Task {
            do {
                // Execute the query and directly attempt to access the `.value` property
                let items: [SupabaseItem] = try await client
                    .from("responses")
                    .select()
                    .execute()
                    .value  // decode the JSON response into the specified Swift type

                print("Fetched items: \(items)")
                completion(items)
            } catch {
                print("Error fetching data: \(error.localizedDescription)")
                completion([])
            }
        }
    }


}
