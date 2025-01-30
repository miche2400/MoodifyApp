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

    private var codeVerifier: String?

    var isTokenValid: Bool {
        guard let expirationDate = UserDefaults.standard.object(forKey: tokenExpirationKey) as? Date else { return false }
        return expirationDate > Date()
    }

    // MARK: - Generate Code Verifier & Challenge for PKCE
    private func generateCodeVerifier() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<128).map { _ in characters.randomElement()! })
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        guard let verifierData = verifier.data(using: .utf8) else { return "" }
        let hashed = SHA256.hash(data: verifierData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Authenticate User with PKCE
    func authenticate(completion: @escaping (Bool) -> Void) {
        let scope = "user-read-private user-read-email playlist-modify-public playlist-modify-private"

        guard let encodedScope = scope.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("❌ Error: Unable to encode scope.")
            completion(false)
            return
        }

        // ✅ Generate PKCE values
        let verifier = generateCodeVerifier()
        let challenge = generateCodeChallenge(from: verifier)

        // ✅ Store `code_verifier` for later token exchange
        UserDefaults.standard.set(verifier, forKey: codeVerifierKey)

        let authURLString = "\(authBaseURL)?client_id=\(clientID)&response_type=code&redirect_uri=\(redirectURI)&scope=\(encodedScope)&code_challenge_method=S256&code_challenge=\(challenge)"

        guard let authURL = URL(string: authURLString) else {
            print("❌ Error: Failed to create authentication URL.")
            completion(false)
            return
        }

        DispatchQueue.main.async {
            UIApplication.shared.open(authURL, options: [:]) { success in
                if success {
                    print("✅ Opened Spotify login successfully.")
                } else {
                    print("❌ Failed to open Spotify login.")
                }
            }
        }
    }

    // MARK: - Handle Redirect URL
    func handleRedirect(url: URL, completion: @escaping (Bool) -> Void) {
        guard let code = URLComponents(string: url.absoluteString)?
                .queryItems?
                .first(where: { $0.name == "code" })?.value else {
            print("❌ Error: No authorization code found in redirect URL.")
            completion(false)
            return
        }

        print("✅ Authorization code received: \(code)")
        exchangeCodeForToken(code: code, completion: completion)
    }

    // MARK: - Exchange Authorization Code for Token (PKCE)
    private func exchangeCodeForToken(code: String, completion: @escaping (Bool) -> Void) {
        guard let codeVerifier = UserDefaults.standard.string(forKey: codeVerifierKey) else {
            print("❌ Error: No stored code verifier for PKCE.")
            completion(false)
            return
        }

        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        let bodyParams = "grant_type=authorization_code&code=\(code)&redirect_uri=\(redirectURI)&client_id=\(clientID)&code_verifier=\(codeVerifier)"
        request.httpBody = bodyParams.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error during token exchange: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let accessToken = json["access_token"] as? String,
                  let expiresIn = json["expires_in"] as? Int else {
                print("❌ Error: Failed to parse token response.")
                completion(false)
                return
            }

            // Save tokens
            UserDefaults.standard.set(accessToken, forKey: self.accessTokenKey)
            UserDefaults.standard.set(Date().addingTimeInterval(TimeInterval(expiresIn)), forKey: self.tokenExpirationKey)

            if let refreshToken = json["refresh_token"] as? String {
                UserDefaults.standard.set(refreshToken, forKey: self.refreshTokenKey)
            }

            print("✅ Access token received successfully.")
            completion(true)
        }.resume()
    }

    // MARK: - Refresh Access Token
    func refreshTokenIfNeeded(completion: @escaping (Bool) -> Void) {
        guard !isTokenValid, let refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey) else {
            completion(isTokenValid)
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
                NotificationCenter.default.post(name: Notification.Name("SpotifyLoginFailure"), object: nil)
                completion(false)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let accessToken = json["access_token"] as? String,
                  let expiresIn = json["expires_in"] as? Int else {
                print("❌ Error: Failed to parse refresh token response.")
                NotificationCenter.default.post(name: Notification.Name("SpotifyLoginFailure"), object: nil)
                completion(false)
                return
            }

            // Update token and expiration
            UserDefaults.standard.set(accessToken, forKey: self.accessTokenKey)
            UserDefaults.standard.set(Date().addingTimeInterval(TimeInterval(expiresIn)), forKey: self.tokenExpirationKey)

            print("✅ Access token refreshed successfully.")
            NotificationCenter.default.post(name: Notification.Name("SpotifyLoginSuccess"), object: nil)
            completion(true)
        }.resume()
    }
}
