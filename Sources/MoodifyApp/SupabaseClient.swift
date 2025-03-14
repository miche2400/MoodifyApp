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
        guard let supabaseURLString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
              let supabaseKey = Bundle.main.infoDictionary?["SUPABASE_KEY"] as? String,
              let supabaseURL = URL(string: supabaseURLString) else {
            fatalError("Supabase credentials are missing in Info.plist")
        }

        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
        
       
    }
    
    func getUserID() async -> String? {
        do {
            let session = try await client.auth.session
            return session.user.id.uuidString // Convert UUID to String
        } catch {
            print("[ERROR] Failed to get user session: \(error.localizedDescription)")
            return nil
        }
    }



    // MARK: - Submit Responses
    func submitResponses(responses: [Response], completion: @escaping (Bool) -> Void) {
        Task {
            do {
                let responseDictionaries = responses.map { response in
                    [
                        "question": response.question,
                        "answer": response.answer
                    ]
                }

                let _ = try await client
                    .from("responses")
                    .insert(responseDictionaries)
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

                let items = try JSONDecoder().decode([SupabaseItem].self, from: response.data)
                print("Fetched items successfully: \(items)")
                completion(items)
            } catch {
                print("Error fetching data: \(error.localizedDescription)")
                completion([])
            }
        }
    }
    
    // MARK: - Store Mood and Playlist Selection in Supabase
    func storeMoodSelection(mood: String, playlistID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            guard let userID = await SupabaseService.shared.getUserID() else {
                print("[ERROR] Cannot store mood selection: User session is missing. Attempting to refresh session...")

                // Try refreshing Supabase auth session
                do {
                    _ = try await client.auth.refreshSession()
                    guard let refreshedUserID = await SupabaseService.shared.getUserID() else {
                        print("[ERROR] Failed to refresh user session.")
                        completion(.failure(NSError(domain: "SupabaseAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User session missing even after refresh."])))
                        return
                    }

                    print("[DEBUG] User session refreshed successfully.")
                    // ❌ Remove `await`
                    saveMoodSelection(userID: refreshedUserID, mood: mood, playlistID: playlistID, completion: completion)
                } catch {
                    print("[ERROR] Could not refresh session: \(error.localizedDescription)")
                    completion(.failure(error))
                }
                return
            }

            // ❌ Remove `await`
            saveMoodSelection(userID: userID, mood: mood, playlistID: playlistID, completion: completion)
        }
    }

    // MARK: - Store Mood and Playlist Selection in Supabase
    private func saveMoodSelection(userID: String, mood: String, playlistID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            let insertData: [String: String] = [
                "mood": mood,
                "playlist_id": playlistID,
                "user_id": userID
            ]

            do {
                try await client
                    .from("moodSelections")
                    .insert(insertData)
                    .execute()

                print("[DEBUG] Mood selection stored successfully in Supabase.")
                completion(.success(()))
            } catch {
                print("[ERROR] Failed to store mood selection: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }



    // MARK: - Fetch Latest Responses (NEW)
    func fetchLatestResponses(completion: @escaping ([Response]) -> Void) {
        Task {
            do {
                let response = try await client
                    .from("responses")
                    .select()
                    .order("created_at", ascending: false) // Get the latest entries
                    .limit(1) // Fetch only the latest response
                    .execute()

                let latestResponses = try JSONDecoder().decode([Response].self, from: response.data)
                print("Latest responses fetched successfully: \(latestResponses)")

                DispatchQueue.main.async {
                    completion(latestResponses)
                }
            } catch {
                print("Failed to fetch latest responses: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
}
