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

    // MARK: - Spotify Credentials
    private let clientID = "97b644c3945e4d0f9ee50f3be6ae9039"
    private let redirectURI = "moodifyapp://callback"
    private let tokenURL = "https://accounts.spotify.com/api/token"
    private let authBaseURL = "https://accounts.spotify.com/authorize"

    // MARK: - UserDefaults Keys
    private let accessTokenKey = "SpotifyAccessToken"
    private let refreshTokenKey = "SpotifyRefreshToken"
    private let tokenExpirationKey = "SpotifyTokenExpirationDate"
    private let codeVerifierKey = "SpotifyCodeVerifier"

    // MARK: - Generate Code Verifier & Challenge (PKCE)
    private func generateCodeVerifier() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<128).compactMap { _ in characters.randomElement() })
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let hashed = SHA256.hash(data: verifier.data(using: .utf8)!)
        return Data(hashed).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }

    // MARK: - Check Token Validity
    var isTokenValid: Bool {
        return getAccessToken() != nil
    }

    // MARK: - Retrieve Current Access Token
    func getAccessToken() -> String? {
        guard let token = UserDefaults.standard.string(forKey: accessTokenKey),
              let expirationDate = UserDefaults.standard.object(forKey: tokenExpirationKey) as? Date,
              expirationDate > Date() else {
            return nil
        }
        return token
    }

    // MARK: - Store Token Data
    private func storeToken(accessToken: String, refreshToken: String?, expiresIn: TimeInterval) {
        UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
        if let refreshToken = refreshToken {
            UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
        }
        let expirationDate = Date().addingTimeInterval(expiresIn)
        UserDefaults.standard.set(expirationDate, forKey: tokenExpirationKey)
        print("[DEBUG] Access token stored. Expires at: \(expirationDate)")
    }

    // MARK: - Handle Spotify Redirect
    func handleRedirect(url: URL, completion: @escaping (Bool) -> Void) {
        print("[DEBUG] Handling redirect: \(url.absoluteString)")
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems,
              let code = queryItems.first(where: { $0.name == "code" })?.value else {
            print("[ERROR] No authorization code found in URL.")
            completion(false)
            return
        }
        exchangeCodeForToken(authCode: code, completion: completion)
    }

    // MARK: - Exchange Auth Code for Token
    private func exchangeCodeForToken(authCode: String, completion: @escaping (Bool) -> Void) {
        print("[DEBUG] Attempting token exchange with auth code: \(authCode)")
        guard let verifier = UserDefaults.standard.string(forKey: codeVerifierKey) else {
            print("[ERROR] No code verifier found in UserDefaults.")
            completion(false)
            return
        }

        let bodyParams: [String: String] = [
            "grant_type": "authorization_code",
            "code": authCode,
            "redirect_uri": redirectURI,
            "client_id": clientID,
            "code_verifier": verifier
        ]

        sendTokenRequest(with: bodyParams, completion: completion)
    }

    // MARK: - Refresh Access Token
    func refreshAccessToken(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey) else {
            completion(false)
            return
        }

        let bodyParams: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientID
        ]

        sendTokenRequest(with: bodyParams, completion: completion)
    }

    // MARK: - Send Token Request
    private func sendTokenRequest(with bodyParams: [String: String], completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[ERROR] Token request failed: \(error.localizedDescription)")
                completion(false)
                return
            }
            guard let data = data,
                  let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let accessToken = jsonResponse["access_token"] as? String,
                  let expiresIn = jsonResponse["expires_in"] as? TimeInterval else {
                print("[ERROR] Invalid response from Spotify API.")
                completion(false)
                return
            }
            let newRefreshToken = jsonResponse["refresh_token"] as? String
            DispatchQueue.main.async {
                self.storeToken(accessToken: accessToken, refreshToken: newRefreshToken, expiresIn: expiresIn)
                completion(true)
            }
        }.resume()
    }

    // MARK: - Authenticate
    func authenticate(completion: @escaping (Bool) -> Void) {
        let scope = "user-read-private user-read-email playlist-modify-public playlist-modify-private"
        let encodedScope = scope.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? scope

        let verifier = generateCodeVerifier()
        let challenge = generateCodeChallenge(from: verifier)
        UserDefaults.standard.set(verifier, forKey: codeVerifierKey)

        let authURLString = "\(authBaseURL)?client_id=\(clientID)&response_type=code&redirect_uri=\(redirectURI)&scope=\(encodedScope)&code_challenge_method=S256&code_challenge=\(challenge)"
        guard let authURL = URL(string: authURLString) else {
            completion(false)
            return
        }
        DispatchQueue.main.async {
            UIApplication.shared.open(authURL) { success in
                completion(success)
            }
        }
    }
}
