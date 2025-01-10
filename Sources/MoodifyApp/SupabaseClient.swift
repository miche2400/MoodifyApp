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
        guard let supabaseURLString = Bundle.main.infoDictionary?["https://djmpjkmbodnteepykdva.supabase.co"] as? String,
              let supabaseKey = Bundle.main.infoDictionary?["eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqbXBqa21ib2RudGVlcHlrZHZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE1MjExODcsImV4cCI6MjA0NzA5NzE4N30.7ftI6sivTBcM21M9Seq68AhCEyVRzouq_7OIDRoeZoI"] as? String,
              let supabaseURL = URL(string: supabaseURLString) else {
            fatalError("Supabase credentials are missing in Info.plist")
        }

        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }

    // MARK: - Submit Responses
    func submitResponses(responses: [Response], completion: @escaping (Bool) -> Void) {
        Task {
            do {
                let response = try await client
                    .from("responses")
                    .insert(responses)
                    .select() // Selecting to get back the inserted data
                    .execute()

                // Directly check the status or print the returned data
                if response.status == 201 {
                    print("Data inserted successfully.")
                    completion(true)
                } else {
                    print("Insertion failed with status: \(response.status)")
                    completion(false)
                }
            } catch {
                print("Error during data insertion: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    // MARK: - Fetch Responses (Fixed)
    func fetchResponses(completion: @escaping ([SupabaseItem]) -> Void) {
        Task {
            do {
                // Execute the query and fetch results
                let response = try await client
                    .from("responses")
                    .select()
                    .execute()

                // Directly use the non-optional response data
                let items = try JSONDecoder().decode([SupabaseItem].self, from: response.data)
                print("Fetched items successfully: \(items)")
                completion(items)
            } catch {
                print("Error fetching data: \(error.localizedDescription)")
                completion([])
            }
        }
    }

}
