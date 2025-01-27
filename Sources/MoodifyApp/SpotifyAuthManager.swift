//
//  SpotifyAuthManager.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 27/01/2025.
//
import Foundation
import UIKit

class SpotifyAuthManager {
    static let shared = SpotifyAuthManager()

    private let clientID = "97b644c3945e4d0f9ee50f3be6ae9039"
    private let clientSecret = "55a2a929f0d749f683dfbc773f19b9b9"
    private let redirectURI = "moodifyapp://callback"

    private var accessToken: String? {
        UserDefaults.standard.string(forKey: "SpotifyAccessToken")
    }

    private var refreshToken: String? {
        UserDefaults.standard.string(forKey: "SpotifyRefreshToken")
    }

    private var tokenExpirationDate: Date? {
        UserDefaults.standard.object(forKey: "SpotifyTokenExpirationDate") as? Date
    }

    var isTokenValid: Bool {
        guard let expirationDate = tokenExpirationDate else { return false }
        return expirationDate > Date()
    }

    // MARK: - Authenticate User
    func authenticate(completion: @escaping (Bool) -> Void) {
        guard let authURL = URL(string: "https://accounts.spotify.com/authorize?client_id=\(clientID)&response_type=code&redirect_uri=\(redirectURI)&scope=user-read-private%20user-read-email%20playlist-modify-public%20playlist-modify-private") else {
            completion(false)
            return
        }

        UIApplication.shared.open(authURL)
    }

    // MARK: - Handle Redirect
    func handleRedirect(url: URL, completion: @escaping (Bool) -> Void) {
        guard let code = URLComponents(string: url.absoluteString)?.queryItems?.first(where: { $0.name == "code" })?.value else {
            print("Error: No authorization code found in redirect URL.")
            completion(false)
            return
        }

        print("Authorization code received: \(code)")
        exchangeCodeForToken(code: code, completion: completion)
    }


    // MARK: - Exchange Authorization Code for Token
    private func exchangeCodeForToken(code: String, completion: @escaping (Bool) -> Void) {
        let tokenURL = "https://accounts.spotify.com/api/token"
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        let bodyParams = "grant_type=authorization_code&code=\(code)&redirect_uri=\(redirectURI)&client_id=\(clientID)&client_secret=\(clientSecret)"
        request.httpBody = bodyParams.data(using: .utf8)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error during token exchange: \(error.localizedDescription)")
                completion(false)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("Token exchange HTTP status: \(httpResponse.statusCode)")
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let accessToken = json["access_token"] as? String,
                  let expiresIn = json["expires_in"] as? Int else {
                print("Error: Failed to parse token exchange response.")
                if let json = try? JSONSerialization.jsonObject(with: data ?? Data(), options: []) {
                    print("Token exchange response JSON: \(json)")
                }
                completion(false)
                return
            }

            // Save tokens and expiration
            let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
            UserDefaults.standard.set(accessToken, forKey: "SpotifyAccessToken")
            UserDefaults.standard.set(json["refresh_token"] as? String, forKey: "SpotifyRefreshToken")
            UserDefaults.standard.set(expirationDate, forKey: "SpotifyTokenExpirationDate")

            print("Access token received: \(accessToken)")
            completion(true)
        }.resume()
    }


    // MARK: - Refresh Access Token
    func refreshTokenIfNeeded(completion: @escaping (Bool) -> Void) {
        guard !isTokenValid, let refreshToken = refreshToken else {
            completion(isTokenValid)
            return
        }

        let tokenURL = "https://accounts.spotify.com/api/token"
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        let bodyParams = "grant_type=refresh_token&refresh_token=\(refreshToken)&client_id=\(clientID)&client_secret=\(clientSecret)"
        request.httpBody = bodyParams.data(using: .utf8)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error refreshing token: \(error.localizedDescription)")
                NotificationCenter.default.post(name: NSNotification.Name("SpotifyLoginFailure"), object: nil)
                completion(false)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let accessToken = json["access_token"] as? String,
                  let expiresIn = json["expires_in"] as? Int else {
                print("Error: Failed to parse refresh token response.")
                NotificationCenter.default.post(name: NSNotification.Name("SpotifyLoginFailure"), object: nil)
                completion(false)
                return
            }

            // Update token and expiration
            let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
            UserDefaults.standard.set(accessToken, forKey: "SpotifyAccessToken")
            UserDefaults.standard.set(expirationDate, forKey: "SpotifyTokenExpirationDate")

            print("Access token refreshed and saved.")
            NotificationCenter.default.post(name: NSNotification.Name("SpotifyLoginSuccess"), object: nil)
            completion(true)
        }.resume()
    }
}
