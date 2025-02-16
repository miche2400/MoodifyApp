//
//  SpotifyAuthManager.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 17/12/2024.
//
import Foundation
import UIKit
import CryptoKit

class SpotifyAuthManager {
    static let shared = SpotifyAuthManager()

    private let clientID = "97b644c3945e4d0f9ee50f3be6ae9039"
    private let redirectURI = "moodifyapp://callback"
    private let tokenURL = "https://accounts.spotify.com/api/token"
    private let authBaseURL = "https://accounts.spotify.com/authorize"

    private let accessTokenKey = "SpotifyAccessToken"
    private let refreshTokenKey = "SpotifyRefreshToken"
    private let tokenExpirationKey = "SpotifyTokenExpirationDate"
    private let codeVerifierKey = "SpotifyCodeVerifier"

    // MARK: - Generate Code Verifier & Challenge for PKCE
    private func generateCodeVerifier() -> String? {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<128).compactMap { _ in characters.randomElement() })
    }

    private func generateCodeChallenge(from verifier: String) -> String? {
        guard let verifierData = verifier.data(using: .utf8) else { return nil }
        let hashed = SHA256.hash(data: verifierData)
        return Data(hashed).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }

    // MARK: - Authenticate User (Triggers Spotify Login)
    func authenticate(completion: @escaping (Bool) -> Void) {
        let scope = "user-read-private user-read-email playlist-modify-public playlist-modify-private"
        guard let encodedScope = scope.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let verifier = generateCodeVerifier(),
              let challenge = generateCodeChallenge(from: verifier) else {
            print("❌ Error in encoding scope or generating verifier.")
            completion(false)
            return
        }

        UserDefaults.standard.set(verifier, forKey: self.codeVerifierKey)
        let authURLString = "\(self.authBaseURL)?client_id=\(self.clientID)&response_type=code&redirect_uri=\(self.redirectURI)&scope=\(encodedScope)&code_challenge_method=S256&code_challenge=\(challenge)"

        guard let authURL = URL(string: authURLString) else {
            print("❌ Error: Failed to create authentication URL.")
            completion(false)
            return
        }

        DispatchQueue.main.async {
            UIApplication.shared.open(authURL) { success in
                print(success ? "✅ Opened Spotify login successfully." : "❌ Failed to open Spotify login.")
                completion(success)
            }
        }
    }

    // MARK: - Token Validity Check
    var isTokenValid: Bool {
        guard let storedAccessToken = UserDefaults.standard.string(forKey: accessTokenKey),
              !storedAccessToken.isEmpty,
              let storedExpiration = UserDefaults.standard.object(forKey: tokenExpirationKey) as? Date else {
            print("⚠️ No valid access token or expiration date found.")
            return false
        }

        let isValid = storedExpiration > Date().addingTimeInterval(300) // 5-minute buffer
        print(isValid ? "✅ Token is valid." : "⚠️ Token is expired or invalid.")
        return isValid
    }

    // MARK: - Handle Redirect URL
    func handleRedirect(url: URL, completion: @escaping (Bool) -> Void) {
        print("🔄 [DEBUG] handleRedirect called with URL: \(url.absoluteString)")

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems,
              let code = queryItems.first(where: { $0.name == "code" })?.value else {
            print("❌ [ERROR] No authorization code found in redirect URL.")
            completion(false)
            return
        }

        print("✅ [DEBUG] Authorization Code Received: \(code)")
        exchangeCodeForToken(code: code, completion: completion)
    }

    // MARK: - Exchange Authorization Code for Token
    func exchangeCodeForToken(code: String, completion: @escaping (Bool) -> Void) {
        print("🔄 [DEBUG] Attempting token exchange...")

        guard let codeVerifier = UserDefaults.standard.string(forKey: codeVerifierKey) else {
            print("❌ No stored code verifier for PKCE.")
            completion(false)
            return
        }

        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        let bodyParams = "grant_type=authorization_code&code=\(code)&redirect_uri=\(redirectURI)&client_id=\(clientID)&code_verifier=\(codeVerifier)"
        request.httpBody = bodyParams.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        print("📡 [DEBUG] Sending request to Spotify...")
        print("🔗 [DEBUG] Request URL: \(tokenURL)")
        print("📜 [DEBUG] Request Body: \(bodyParams)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [ERROR] Token exchange error: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [ERROR] No HTTP response from Spotify.")
                completion(false)
                return
            }

            print("🛰 [DEBUG] Received Response: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200, let data = data else {
                print("❌ [ERROR] Invalid response or status code: \(httpResponse.statusCode)")
                completion(false)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("📜 [DEBUG] Spotify Response JSON: \(json)")

                    if let accessToken = json["access_token"] as? String,
                       let expiresIn = json["expires_in"] as? Int {
                        
                        print("✅ Access token received: \(accessToken)")

                        let refreshToken = json["refresh_token"] as? String ?? UserDefaults.standard.string(forKey: self.refreshTokenKey)

                        UserDefaults.standard.set(accessToken, forKey: self.accessTokenKey)
                        UserDefaults.standard.set(refreshToken, forKey: self.refreshTokenKey)
                        UserDefaults.standard.set(Date().addingTimeInterval(TimeInterval(expiresIn)), forKey: self.tokenExpirationKey)

                        print("✅ Successfully stored access & refresh token.")
                        completion(true)
                    } else {
                        print("❌ [ERROR] Failed to parse token response.")
                        completion(false)
                    }
                }
            } catch {
                print("❌ [ERROR] JSON parsing error: \(error.localizedDescription)")
                completion(false)
            }
        }.resume()
    }


    // MARK: - Refresh Access Token
    func refreshAccessToken(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey) else {
            print("⚠️ No refresh token available. User must log in again.")
            completion(false)
            return
        }

        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        let bodyParams = "grant_type=refresh_token&refresh_token=\(refreshToken)&client_id=\(clientID)"
        request.httpBody = bodyParams.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error refreshing token: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let data = data else {
                print("❌ No data received.")
                completion(false)
                return
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let newAccessToken = jsonResponse["access_token"] as? String {
                    UserDefaults.standard.set(newAccessToken, forKey: "SpotifyAccessToken")
                    print("✅ New access token saved: \(newAccessToken)")
                    completion(true)
                } else {
                    print("❌ Failed to parse access token from response.")
                    completion(false)
                }
            } catch {
                print("❌ JSON parsing error: \(error.localizedDescription)")
                completion(false)
            }

            print("✅ Access token refreshed successfully.")
            completion(true)
        }.resume()
    }
}
