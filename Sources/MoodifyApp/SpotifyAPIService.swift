//
//  SpotifyAPIService.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 16/02/2025.
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
                let error = NSError(domain: "SpotifyAPI",
                                    code: 401,
                                    userInfo: [NSLocalizedDescriptionKey: "Unable to authenticate."])
                completion(.failure(error))
                return
            }

            guard let accessToken = UserDefaults.standard.string(forKey: self.accessTokenKey) else {
                let error = NSError(domain: "SpotifyAPI",
                                    code: 401,
                                    userInfo: [NSLocalizedDescriptionKey: "No access token."])
                completion(.failure(error))
                return
            }

            let url = URL(string: "\(self.baseURL)/me")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error fetching user profile: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard
                    let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode == 200,
                    let data = data
                else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    print("Failed to fetch profile. Status code: \(statusCode)")
                    let error = NSError(domain: "SpotifyAPI",
                                        code: statusCode,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid response."])
                    completion(.failure(error))
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("User Profile: \(json)")
                        completion(.success(json))
                    }
                } catch {
                    print("JSON Parsing Error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
            .resume()
        }
    }

    // MARK: - Fetch User Playlists
    func fetchUserPlaylists(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        validateToken { [weak self] success in
            guard success, let self = self else {
                let error = NSError(domain: "SpotifyAPI",
                                    code: 401,
                                    userInfo: [NSLocalizedDescriptionKey: "Unable to authenticate."])
                completion(.failure(error))
                return
            }

            guard let accessToken = UserDefaults.standard.string(forKey: self.accessTokenKey) else {
                let error = NSError(domain: "SpotifyAPI",
                                    code: 401,
                                    userInfo: [NSLocalizedDescriptionKey: "No access token."])
                completion(.failure(error))
                return
            }

            let url = URL(string: "\(self.baseURL)/me/playlists")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error fetching playlists: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard
                    let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode == 200,
                    let data = data
                else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    print("Failed to fetch playlists. Status code: \(statusCode)")
                    let error = NSError(domain: "SpotifyAPI",
                                        code: statusCode,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid response."])
                    completion(.failure(error))
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print(" Playlists: \(json)")
                        completion(.success(json))
                    }
                } catch {
                    print("JSON Parsing Error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
            .resume()
        }
    }

    // MARK: - Open Playlist (In-App)
    func openPlaylist(playlistID: String) {
        let spotifyURLString = "spotify://playlist/\(playlistID)"
        
        if let spotifyURL = URL(string: spotifyURLString),
           UIApplication.shared.canOpenURL(spotifyURL) {
            print("Opening Spotify URL: \(spotifyURLString)")
            UIApplication.shared.open(spotifyURL)
        } else {
            // Fallback to web if Spotify is not installed
            let webURLString = "https://open.spotify.com/playlist/\(playlistID)"
            print("Falling back to web URL: \(webURLString)")
            if let webURL = URL(string: webURLString) {
                UIApplication.shared.open(webURL)
            }
        }
    }

    // MARK: - Validate Token Before Making API Calls
    private func validateToken(completion: @escaping (Bool) -> Void) {
        if SpotifyAuthManager.shared.getAccessToken() != nil {
            completion(true)
        } else {
            print(" Token expired. Refreshing...")
            SpotifyAuthManager.shared.refreshAccessToken { success in
                completion(success)
            }
        }
    }
}
