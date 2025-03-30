//
//  SpotifyAPIService.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 16/02/2025.
//
//

import UIKit
import Foundation

class SpotifyAPIService {
    static let shared = SpotifyAPIService()
    
    private let baseURL = "https://api.spotify.com/v1"
    private let accessTokenKey = "SpotifyAccessToken"

    // MARK: - Fetch User Profile
    func fetchUserProfile(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        validateToken { [weak self] success in
            guard success, let self = self else {
                completion(.failure(NSError(domain: "SpotifyAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unable to authenticate."])))
                return
            }

            guard let accessToken = UserDefaults.standard.string(forKey: self.accessTokenKey) else {
                completion(.failure(NSError(domain: "SpotifyAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "No access token."])))
                return
            }

            let url = URL(string: "\(self.baseURL)/me")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let data = data else {
                    completion(.failure(NSError(
                        domain: "SpotifyAPI",
                        code: (response as? HTTPURLResponse)?.statusCode ?? 0,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response."]
                    )))
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        completion(.success(json))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
            .resume()
        }
    }

    // MARK: - Create Playlist and Store in Supabase
    // Swift
    func createAndSavePlaylist(mood: String, songNames: [String], completion: @escaping (Result<String, Error>) -> Void) {
        fetchUserProfile { result in
            switch result {
            case .success(let profile):
                guard let userID = profile["id"] as? String else {
                    completion(.failure(NSError(
                        domain: "SpotifyAPI",
                        code: 500,
                        userInfo: [NSLocalizedDescriptionKey: "User ID not found."]
                    )))
                    return
                }
                OpenAIService.shared.generatePlaylistTitle(from: mood) { titleResult in
                    switch titleResult {
                    case .success(let title):
                        self.createPlaylist(userID: userID, title: title, mood: mood) { playlistResult in
                            switch playlistResult {
                            case .success(let playlistID):
                                // Search for recommended track IDs based on song names
                                self.searchForTracks(songNames: songNames) { trackResult in
                                    switch trackResult {
                                    case .success(let recommendedTrackIDs):
                                        // Get liked songs and merge them with recommended tracks
                                        self.fetchLikedSongs { likedResult in
                                            switch likedResult {
                                            case .success(let likedTrackIDs):
                                                let combinedTrackIDs = Array(Set(recommendedTrackIDs + likedTrackIDs))
                                                self.addTracksToPlaylist(playlistID: playlistID, trackIDs: combinedTrackIDs) { addResult in
                                                    switch addResult {
                                                    case .success:
                                                        // Store the mood selection with title in Supabase
                                                        SupabaseService.shared.storeMoodSelection(
                                                            spotifyUserID: userID,
                                                            mood: mood,
                                                            playlistID: playlistID,
                                                            title: title
                                                        ) { storeResult in
                                                            switch storeResult {
                                                            case .success:
                                                                completion(.success(playlistID))
                                                            case .failure(let error):
                                                                completion(.failure(error))
                                                            }
                                                        }
                                                    case .failure(let error):
                                                        completion(.failure(error))
                                                    }
                                                }
                                            case .failure(let error):
                                                completion(.failure(error))
                                            }
                                        }
                                    case .failure(let error):
                                        completion(.failure(error))
                                    }
                                }
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Create Playlist on Spotify
    func createPlaylist(userID: String, title: String, mood: String, completion: @escaping (Result<String, Error>) -> Void) {
        validateToken { [weak self] success in
            guard success, let self = self else {
                completion(.failure(NSError(domain: "SpotifyAPI", code: 401,
                                            userInfo: [NSLocalizedDescriptionKey: "Authentication failed."])))
                return
            }

            guard let accessToken = UserDefaults.standard.string(forKey: self.accessTokenKey) else {
                completion(.failure(NSError(domain: "SpotifyAPI", code: 401,
                                            userInfo: [NSLocalizedDescriptionKey: "No access token found."])))
                return
            }
            
            // Use the AI generated title as the playlist name.
            let playlistTitle = title
            
            var playlistDescription = "Curated for your \(mood) vibes."
            if playlistDescription.count > 300 {
                playlistDescription = String(playlistDescription.prefix(300)) + "..."
            }
            
            let requestBody: [String: Any] = [
                "name": playlistTitle,
                "description": playlistDescription,
                "public": false
            ]
            
            let url = URL(string: "\(self.baseURL)/users/\(userID)/playlists")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                    completion(.failure(NSError(domain: "SpotifyAPI", code: 500,
                                                userInfo: [NSLocalizedDescriptionKey: "Failed to create playlist."])))
                    return
                }
                
                if httpResponse.statusCode != 201 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    completion(.failure(NSError(domain: "SpotifyAPI", code: httpResponse.statusCode,
                                                userInfo: [NSLocalizedDescriptionKey: "Failed to create playlist: \(errorMessage)"])))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let playlistID = json["id"] as? String {
                        completion(.success(playlistID))
                    } else {
                        completion(.failure(NSError(domain: "SpotifyAPI", code: 500,
                                                    userInfo: [NSLocalizedDescriptionKey: "Failed to parse playlist ID."])))
                    }
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        }
    }
    
    // MARK: - Add Tracks to Spotify Playlist
    func addTracksToPlaylist(playlistID: String, trackIDs: [String], completion: @escaping (Result<Bool, Error>) -> Void) {
        validateToken { [weak self] success in
            guard success, let self = self else {
                completion(.failure(NSError(domain: "SpotifyAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication failed."])))
                return
            }

            guard let accessToken = UserDefaults.standard.string(forKey: self.accessTokenKey) else {
                completion(.failure(NSError(domain: "SpotifyAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "No access token found."])))
                return
            }

            let uris = trackIDs.map { "spotify:track:\($0)" }
            // Fixed URL endpoint to use /playlists instead of /moodSelections
            let url = URL(string: "\(self.baseURL)/playlists/\(playlistID)/tracks")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let requestBody: [String: Any] = ["uris": uris]
            request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("[ERROR] Adding tracks failed: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                    print("[ERROR] Failed to add tracks to playlist")
                    completion(.failure(NSError(domain: "SpotifyAPI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to add tracks to playlist."])))
                    return
                }

                print("[DEBUG] Tracks added successfully!")
                completion(.success(true))
            }.resume()
        }
    }
    
    // MARK: - Search for Tracks
    func searchForTracks(songNames: [String], completion: @escaping (Result<[String], Error>) -> Void) {
        validateToken { [weak self] success in
            guard success, let self = self else {
                completion(.failure(NSError(domain: "SpotifyAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication failed."])))
                return
            }

            var trackIDs: [String] = []
            let trackIDQueue = DispatchQueue(label: "trackIDQueue")

            let dispatchGroup = DispatchGroup()

            for song in songNames {
                let query = song.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                let url = URL(string: "\(self.baseURL)/search?q=\(query)&type=track&limit=1")!
                guard let accessToken = UserDefaults.standard.string(forKey: self.accessTokenKey) else {
                    completion(.failure(NSError(domain: "SpotifyAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "No access token found."])))
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                dispatchGroup.enter()
                URLSession.shared.dataTask(with: request) { data, response, error in
                    defer { dispatchGroup.leave() }
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let tracks = json["tracks"] as? [String: Any],
                       let items = tracks["items"] as? [[String: Any]],
                       let trackID = items.first?["id"] as? String {
                        trackIDQueue.sync {
                            trackIDs.append(trackID)
                        }
                    }
                }.resume()
            }

            dispatchGroup.notify(queue: .main) {
                if trackIDs.isEmpty {
                    completion(.failure(NSError(
                        domain: "SpotifyAPI",
                        code: 500,
                        userInfo: [NSLocalizedDescriptionKey: "No valid tracks found."]
                    )))
                } else {
                    completion(.success(trackIDs))
                }
            }
        }
    }

    // MARK: - Validate Token
    private func validateToken(completion: @escaping (Bool) -> Void) {
        guard let expirationDate = UserDefaults.standard.object(forKey: "SpotifyTokenExpiration") as? Date else {
            SpotifyAuthManager.shared.refreshAccessToken { success in completion(success) }
            return
        }

        if Date() < expirationDate {
            print("[DEBUG] Using existing Spotify access token.")
            completion(true) // Skip refresh if token is still valid
        } else {
            SpotifyAuthManager.shared.refreshAccessToken { success in completion(success) }
        }
    }
    // MARK: - Fetch Liked Songs
    func fetchLikedSongs(completion: @escaping (Result<[String], Error>) -> Void) {
        validateToken { [weak self] success in
            guard success, let self = self else {
                completion(.failure(NSError(domain: "SpotifyAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication failed."])))
                return
            }

            guard let accessToken = UserDefaults.standard.string(forKey: self.accessTokenKey) else {
                completion(.failure(NSError(domain: "SpotifyAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "No access token found."])))
                return
            }

            // Fetch liked songs (saved tracks) from the Spotify API
            let url = URL(string: "\(self.baseURL)/me/tracks?limit=50")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let data = data else {
                    completion(.failure(NSError(domain: "SpotifyAPI", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data received."])))
                    return
                }
                do {
                    // Parse the saved tracks JSON; adjust the Codable types as necessary
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let items = json["items"] as? [[String: Any]] {
                        let trackIDs: [String] = items.compactMap { item in
                            if let track = item["track"] as? [String: Any],
                               let id = track["id"] as? String {
                                return id
                            }
                            return nil
                        }
                        completion(.success(trackIDs))
                    } else {
                        completion(.failure(NSError(domain: "SpotifyAPI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response format."])))
                    }
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        }
    }
}
