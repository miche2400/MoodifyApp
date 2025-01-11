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
        guard let supabaseURLString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
              let supabaseKey = Bundle.main.infoDictionary?["SUPABASE_KEY"] as? String,
              let supabaseURL = URL(string: supabaseURLString) else {
            fatalError("Supabase credentials are missing in Info.plist")
        }

        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }

    // MARK: - Submit Responses
    func submitResponses(responses: [Response], completion: @escaping (Bool) -> Void) {
        Task {
            do {
                let _ = try await client
                    .from("responses")
                    .insert(responses)
                    .execute()
                
                print("Data inserted successfully.")
                completion(true)
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
                let response = try await client
                    .from("responses")
                    .select()
                    .execute()
                
                // Directly use response.data since it's non-optional
                let items = try JSONDecoder().decode([SupabaseItem].self, from: response.data)
                print("Fetched items successfully: \(items)")
                completion(items)
            } catch {
                print("Error fetching data: \(error.localizedDescription)")
                completion([])  // Return an empty array in case of error
            }
        }
    }


}
