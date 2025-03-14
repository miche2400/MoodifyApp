//
//  OpenAIService.swift
//  Moodify
//
//  Created by Michelle Rodriguez on 18/02/2025.
//


import Foundation

enum OpenAIError: Error {
    case missingAPIKey
    case requestFailed(String)
    case decodingFailed
    case noMoodDetected
    case rateLimited
}

class OpenAIService {
    static let shared = OpenAIService()
    
    private let openAIKey: String? = {
        guard let key = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String else {
            print("[ERROR] OpenAI API Key is missing in Info.plist!")
            return nil
        }
        return key.isEmpty ? nil : key
    }()
    
    private let openAIEndpoint = "https://api.openai.com/v1/chat/completions"
    
    func classifyMood(
        responses: [Response],
        completion: @escaping (Result<String, OpenAIError>) -> Void
    ) {
        let userPrompt = buildPrompt(from: responses)
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that determines a user's mood from a list of statements."],
                ["role": "user", "content": userPrompt]
            ],
            "max_tokens": 50,
            "temperature": 0.7
        ]
        
        sendOpenAIRequest(requestBody: requestBody, completion: completion)
    }
    
    func generatePlaylist(from responses: [Response], completion: @escaping (Result<String, OpenAIError>) -> Void) {
        classifyMood(responses: responses) { result in
            switch result {
            case .success(let mood):
                let songPrompt = """
                Based on the mood '\(mood)', suggest a Spotify playlist with 10 songs.
                Format: Provide only the song names and artist in a comma-separated list.
                """
                
                let requestBody: [String: Any] = [
                    "model": "gpt-3.5-turbo",
                    "messages": [
                        ["role": "system", "content": "You are a music assistant that provides song recommendations based on mood."],
                        ["role": "user", "content": songPrompt]
                    ],
                    "max_tokens": 150,
                    "temperature": 0.7
                ]
                
                self.sendOpenAIRequest(requestBody: requestBody) { result in
                    switch result {
                    case .success(let playlistText):
                        let songLines = playlistText.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        let songNames = songLines.filter { !$0.isEmpty && $0.contains(" by ") }
                        
                        if songNames.isEmpty {
                            completion(.failure(.decodingFailed))
                            return
                        }
                        
                        SpotifyAPIService.shared.searchForTracks(songNames: songNames) { trackResult in
                            switch trackResult {
                            case .success(let trackIDs):
                                SpotifyAPIService.shared.fetchUserProfile { userResult in
                                    switch userResult {
                                    case .success(let profile):
                                        guard let userID = profile["id"] as? String else {
                                            completion(.failure(.requestFailed("User ID not found.")))
                                            return
                                        }
                                        
                                        SpotifyAPIService.shared.createPlaylist(userID: userID, mood: mood) { playlistResult in
                                            switch playlistResult {
                                            case .success(let playlistID):
                                                SpotifyAPIService.shared.addTracksToPlaylist(playlistID: playlistID, trackIDs: trackIDs) { addResult in
                                                    switch addResult {
                                                    case .success:
                                                        SupabaseService.shared.storeMoodSelection(mood: mood, playlistID: playlistID) { storeResult in
                                                            switch storeResult {
                                                            case .success:
                                                                completion(.success(playlistID))
                                                            case .failure(let error):
                                                                completion(.failure(.requestFailed(error.localizedDescription)))
                                                            }
                                                        }
                                                    case .failure(let error):
                                                        completion(.failure(.requestFailed(error.localizedDescription)))
                                                    }
                                                }
                                            case .failure(let error):
                                                completion(.failure(.requestFailed(error.localizedDescription)))
                                            }
                                        }
                                    case .failure(let error):
                                        completion(.failure(.requestFailed(error.localizedDescription)))
                                    }
                                }
                            case .failure(let error):
                                completion(.failure(.requestFailed(error.localizedDescription)))
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
    
    private func sendOpenAIRequest(
        requestBody: [String: Any],
        retryCount: Int = 0,
        completion: @escaping (Result<String, OpenAIError>) -> Void
    ) {
        guard let apiKey = openAIKey else {
            completion(.failure(.missingAPIKey))
            return
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(.decodingFailed))
            return
        }
        
        var request = URLRequest(url: URL(string: openAIEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[ERROR] OpenAI request failed: \(error.localizedDescription)")
                completion(.failure(.requestFailed(error.localizedDescription)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                print("[ERROR] OpenAI response invalid: No data received")
                completion(.failure(.requestFailed("Invalid response from OpenAI API.")))
                return
            }

            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("[ERROR] OpenAI API Error \(httpResponse.statusCode): \(errorMessage)")
                completion(.failure(.requestFailed(errorMessage)))
                return
            }
            do {
                let responseString = String(data: data, encoding: .utf8) ?? "N/A"
                print("[DEBUG] Raw OpenAI Response: \(responseString)")

                let decodedResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
                if let responseText = decodedResponse.choices.first?.message.content {
                    print("[DEBUG] OpenAI Response: \(responseText)")
                    completion(.success(responseText))
                } else {
                    print("[ERROR] OpenAI response did not contain valid content.")
                    completion(.failure(.decodingFailed))
                }
            } catch {
                print("[ERROR] Failed to decode OpenAI response: \(error.localizedDescription)")
                completion(.failure(.decodingFailed))
            }
        }.resume()

    }
    
    private func buildPrompt(from responses: [Response]) -> String {
        var result = "Determine the user’s overall mood from these statements:\n"
        for (index, resp) in responses.enumerated() {
            result += "\(index + 1)) Question: \"\(resp.question)\"\n   Answer: \"\(resp.answer)\"\n\n"
        }
        result += "Please give me one of these moods: Happy, Sad, Relaxed, Energetic, or Sleepy.\n"
        return result
    }
    
    struct OpenAIChatResponse: Codable {
        let choices: [Choice]
        struct Choice: Codable {
            let message: Message
            struct Message: Codable {
                let role: String
                let content: String
            }
        }
    }
}
