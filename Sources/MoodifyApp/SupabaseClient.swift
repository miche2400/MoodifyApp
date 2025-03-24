//
//  SupabaseClient.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 17/12/2024.
//
//
//  SupabaseClient.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 17/12/2024.
//

import Foundation
import Supabase
import PostgREST

class SupabaseService {
    static let shared = SupabaseService()
    
    public let client: SupabaseClient
    
    // store your custom PostgrestClient
    private var customPostgrest: PostgrestClient?
    
    var auth: AuthClient {
        return client.auth
    }
    
    private init() {
        guard let supabaseURLString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
              let supabaseKey = Bundle.main.infoDictionary?["SUPABASE_KEY"] as? String,
              let supabaseURL = URL(string: supabaseURLString) else {
            fatalError("Supabase credentials are missing in Info.plist")
        }
                
        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }
    
    func fetchSomething() async {
        guard let customClient = customPostgrest else {
            print("[ERROR] Not logged in; no PostgrestClient available.")
            return
        }

        do {
            let response = try await customClient
                .from("some_table")
                .select()
                .execute()

            let rawString = String(data: response.data, encoding: .utf8) ?? "No data"
            print("Got data: \(rawString)")
        } catch {
            print("Query failed: \(error)")
        }
    }
    
    
    // MARK: - Login with Spotify OAuth Token
    func loginWithSpotify(token: String) async -> Bool {
        do {
            // 1) Construct request to your Edge Function URL
            guard let url = URL(string: "https://djmpjkmbodnteepykdva.supabase.co/functions/v1/exchange-spotify-token")
            else {
                fatalError("Invalid Edge Function URL")
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // 2) Load the anon key from Info.plist
            guard let anonKey = Bundle.main.infoDictionary?["SUPABASE_KEY"] as? String else {
                fatalError("Supabase anon key not found in Info.plist")
            }

            // 3) Provide the Authorization header so the function won’t return 401
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

            // 4) Send the Spotify token in the POST body
            let requestBody: [String: String] = ["spotifyAccessToken": token]
            request.httpBody = try JSONEncoder().encode(requestBody)

            // 5) Perform the network request
            let (data, _) = try await URLSession.shared.data(for: request)

            // 6) Debug print the raw response text
            let rawString = String(data: data, encoding: .utf8) ?? "No response data"
            print("[DEBUG] Raw response from exchange-spotify-token:\n\(rawString)")

            // 7) Decode the JSON into a dictionary
            let responseJSON = try JSONDecoder().decode([String: String].self, from: data)

            // 8) Extract "supabaseJWT"
            guard let supabaseJWT = responseJSON["supabaseJWT"] else {
                print("[ERROR] Missing 'supabaseJWT' in response.")
                return false
            }
            print("[DEBUG] SSO login successful. JWT = \(supabaseJWT)")
            return true

        } catch {
            print("[ERROR] Failed to SSO login: \(error.localizedDescription)")
            return false
        }
    }
    
    
    // MARK: - Save Playlist to Supabase
    func savePlaylistToSupabase(mood: String, playlistURL: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            // Here we fetch the Spotify user ID from the Spotify API (or pass it in from another part of your app)
            guard let token = UserDefaults.standard.string(forKey: "SpotifyAccessToken"),
                  !token.isEmpty,
                  let spotifyUserID = await fetchSpotifyUserID(accessToken: token) else {
                print("[ERROR] No Spotify token or user ID found. Cannot store playlist.")
                completion(.failure(NSError(domain: "SpotifyAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Spotify token or user ID missing."])))
                return
            }

            let newPlaylist = [
                "user_id": spotifyUserID, // Store Spotify user ID directly as text
                "mood": mood,
                "playlist_url": playlistURL,
                "created_at": ISO8601DateFormatter().string(from: Date())
            ]

            do {
                try await client
                    .from("playlists")
                    .insert(newPlaylist)
                    .execute()

                print("[DEBUG] Playlist successfully saved in Supabase.")
                completion(.success(()))
            } catch {
                print("[ERROR] Failed to save playlist: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    
    // MARK: - Fetch User Playlists
    func fetchUserPlaylists(completion: @escaping ([Playlist]) -> Void) {
        Task {
            // We now fetch playlists based on Spotify user ID.
            guard let token = UserDefaults.standard.string(forKey: "SpotifyAccessToken"),
                  !token.isEmpty,
                  let spotifyUserID = await fetchSpotifyUserID(accessToken: token) else {
                print("[ERROR] No Spotify user ID found.")
                completion([])
                return
            }

            print("[DEBUG] Fetching playlists for Spotify user ID: \(spotifyUserID)")

            do {
                let response = try await client
                    .from("playlists")
                    .select()
                    .eq("user_id", value: spotifyUserID) // using text comparison
                    .execute()

                let rawResponse = String(data: response.data, encoding: .utf8) ?? "No data"
                print("[DEBUG] Raw Supabase Response: \(rawResponse)")

                let playlists = try JSONDecoder().decode([Playlist].self, from: response.data)
                DispatchQueue.main.async {
                    completion(playlists)
                }
            } catch {
                print("[ERROR] Supabase query failed: \(error.localizedDescription)")
                completion([])
            }
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
    func fetchResponses(completion: @escaping ([Response]) -> Void) {
        Task {
            do {
                let response = try await client
                    .from("responses")
                    .select()
                    .execute()

                let items = try JSONDecoder().decode([Response].self, from: response.data)
                print("Fetched items successfully: \(items)")
                completion(items)
            } catch {
                print("Error fetching data: \(error.localizedDescription)")
                completion([])
            }
        }
    }
    
    
    // MARK: - Fetch Latest Responses
    func fetchLatestResponses(completion: @escaping ([Response]) -> Void) {
        Task {
            do {
                let response = try await client
                    .from("responses")
                    .select()
                    .order("created_at", ascending: false)
                    .limit(5)  // Fetch the last 5 responses
                    .execute()

                let latestResponses = try JSONDecoder().decode([Response].self, from: response.data)
                print("[DEBUG] Latest responses fetched successfully: \(latestResponses)")

                DispatchQueue.main.async {
                    completion(latestResponses)
                }
            } catch {
                print("[ERROR] Failed to fetch latest responses: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    
    // MARK: - Store Mood and Playlist Selection in Supabase
    func storeMoodSelection(spotifyUserID: String, mood: String, playlistID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            let moodSelection = [
                "user_id": spotifyUserID,  // This is the Spotify user ID as text
                "mood": mood,
                "playlist_id": playlistID,
                "created_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            do {
                try await client
                    .from("moodSelections")
                    .insert(moodSelection)
                    .execute()
                
                print("[DEBUG] Mood selection successfully stored.")
                completion(.success(()))
            } catch {
                print("[ERROR] Failed to store mood selection: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Spotify API Helper
struct SpotifyUserProfile: Decodable {
    let id: String
    let display_name: String?
    let email: String?
    // Add more fields if needed
}

func fetchSpotifyUserID(accessToken: String) async -> String? {
    let url = URL(string: "https://api.spotify.com/v1/me")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    
    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        let profile = try JSONDecoder().decode(SpotifyUserProfile.self, from: data)
        return profile.id  // the Spotify user ID as a String
    } catch {
        print("[ERROR] Could not fetch Spotify user ID: \(error.localizedDescription)")
        return nil
    }
}
