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
                let response = try await client
                    .from("responses")
                    .insert(responses)
                    .execute()

                if response.error == nil {
                    print("Data inserted successfully.")
                    completion(true)
                } else {
                    print("Error inserting data: \(response.error?.localizedDescription ?? "Unknown error")")
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
                let response = try await client
                    .from("responses")
                    .select()
                    .execute()

                guard response.error == nil, let data = response.data else {
                    print("Error fetching data: \(response.error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }

                let items = try JSONDecoder().decode([SupabaseItem].self, from: data)
                print("Fetched items successfully: \(items)")
                completion(items)
            } catch {
                print("Error fetching data: \(error.localizedDescription)")
                completion([])
            }
        }
    }
}
