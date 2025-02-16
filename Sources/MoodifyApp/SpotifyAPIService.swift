//
//  SpotifyAPIService.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 16/02/2025.
//

import Foundation

class SpotifyAPIService {
    static let shared = SpotifyAPIService()
    
    private let baseURL = "https://api.spotify.com/v1"
    private let accessTokenKey = "SpotifyAccessToken"

    // MARK: - Fetch User Profile
    func fetchUserProfile(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let accessToken = UserDefaults.standard.string(forKey: accessTokenKey) else {
            print("❌ No access token available.")
            completion(.failure(NSError(domain: "SpotifyAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "No access token."])))
            return
        }

        let url = URL(string: "\(baseURL)/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error fetching user profile: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  let data = data else {
                print("❌ Failed to fetch profile. Status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                completion(.failure(NSError(domain: "SpotifyAPI", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid response."])))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("✅ User Profile: \(json)")
                    completion(.success(json))
                }
            } catch {
                print("❌ JSON Parsing Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Fetch User Playlists
    func fetchUserPlaylists(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let accessToken = UserDefaults.standard.string(forKey: accessTokenKey) else {
            print("❌ No access token available.")
            completion(.failure(NSError(domain: "SpotifyAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "No access token."])))
            return
        }

        let url = URL(string: "\(baseURL)/me/playlists")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error fetching playlists: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  let data = data else {
                print("❌ Failed to fetch playlists. Status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                completion(.failure(NSError(domain: "SpotifyAPI", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid response."])))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("✅ Playlists: \(json)")
                    completion(.success(json))
                }
            } catch {
                print("❌ JSON Parsing Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
}
