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

// MARK: - OpenAI API Response Model
struct OpenAIChatResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let role: String
        let content: String
    }
}

protocol OpenAIServiceProtocol {
    func generatePlaylistTitle(from mood: String, completion: @escaping (Result<String, OpenAIError>) -> Void)
}

class OpenAIService: OpenAIServiceProtocol {
    static let shared = OpenAIService()
    
    private let openAIKey: String? = {
        guard let key = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String else {
            print("[ERROR] OpenAI API Key is missing in Info.plist!")
            return nil
        }
        return key.isEmpty ? nil : key
    }()
    
    private let openAIEndpoint = "https://api.openai.com/v1/chat/completions"

    // MARK: - Mood Classification
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

    // MARK: - Generate Playlist from Responses
    func generatePlaylist(
        from responses: [Response],
        completion: @escaping (Result<String, OpenAIError>) -> Void
    ) {
        classifyMood(responses: responses) { moodResult in
            switch moodResult {
            case .success(let mood):
                self.fetchPlaylist(for: mood, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Fetch Playlist Based on Mood
    private func fetchPlaylist(
        for mood: String,
        completion: @escaping (Result<String, OpenAIError>) -> Void
    ) {
        let songPrompt = """
        Based on the mood '\(mood)', suggest a Spotify playlist with 10 songs. Do not include any karaoke tracks or songs that are typically performed as karaoke. Format: Provide only the song names followed by the artist, each on a new line.
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
        
        sendOpenAIRequest(requestBody: requestBody) { result in
            switch result {
            case .success(let playlistText):
                let songNames = playlistText
                    .components(separatedBy: "\n")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty && $0.contains(" by ") }
                
                if songNames.isEmpty {
                    completion(.failure(.decodingFailed))
                    return
                }

                self.createSpotifyPlaylist(mood: mood, songNames: songNames, completion: completion)
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Create Spotify Playlist
    private func createSpotifyPlaylist(
        mood: String,
        songNames: [String],
        completion: @escaping (Result<String, OpenAIError>) -> Void
    ) {
        // 1) Search for track IDs based on the given songNames
        SpotifyAPIService.shared.searchForTracks(songNames: songNames) { trackResult in
            switch trackResult {
            case .success(let trackIDs):
                // 2) Fetch the Spotify user's profile to get userID
                SpotifyAPIService.shared.fetchUserProfile { userResult in
                    switch userResult {
                    case .success(let profile):
                        guard let userID = profile["id"] as? String else {
                            completion(.failure(.requestFailed("User ID not found.")))
                            return
                        }

                        // 3) Generate a playlist title using OpenAI based on mood
                        self.generatePlaylistTitle(from: mood) { titleResult in
                            switch titleResult {
                            case .success(let title):
                                // 4) Create a playlist for this user with the generated title
                                SpotifyAPIService.shared.createPlaylist(userID: userID, title: title, mood: mood) { playlistResult in
                                    switch playlistResult {
                                    case .success(let playlistID):
                                        // 5) Add the found tracks to the newly created playlist
                                        SpotifyAPIService.shared.addTracksToPlaylist(
                                            playlistID: playlistID,
                                            trackIDs: trackIDs
                                        ) { addResult in
                                            switch addResult {
                                            case .success:
                                                // 6) Store mood selection with title in Supabase
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
                        completion(.failure(.requestFailed(error.localizedDescription)))
                    }
                }
            case .failure(let error):
                completion(.failure(.requestFailed(error.localizedDescription)))
            }
        }
    }


    // MARK: - OpenAI API Request
    private func sendOpenAIRequest(
        requestBody: [String: Any],
        retryCount: Int = 0,
        completion: @escaping (Result<String, OpenAIError>) -> Void
    ) {
        guard let apiKey = openAIKey else {
            print("[ERROR] OpenAI API Key is missing.")
            completion(.failure(.missingAPIKey))
            return
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("[ERROR] Failed to encode OpenAI request.")
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

            if httpResponse.statusCode == 429 {
                print("[ERROR] OpenAI API rate limited. Retrying in 5 seconds...")
                if retryCount < 3 {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                        self.sendOpenAIRequest(requestBody: requestBody, retryCount: retryCount + 1, completion: completion)
                    }
                } else {
                    completion(.failure(.rateLimited))
                }
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
                print("[DEBUG] OpenAI Raw Data: \(String(data: data, encoding: .utf8) ?? "N/A")")
                completion(.failure(.decodingFailed))
            }
        }.resume()
    }

    
    // MARK: - Build Prompt for OpenAI
    func buildPrompt(from responses: [Response]) -> String {
        var result = "Determine the user’s overall mood from these statements:\n"
        for (index, resp) in responses.enumerated() {
            result += "\(index + 1)) Question: \"\(resp.question)\"\n   Answer: \"\(resp.answer)\"\n\n"
        }
        result += "Please give me one of these moods: Happy, Sad, Relaxed, Energetic, or Sleepy.\n"
        return result
    }
    
    func generatePlaylistTitle(from mood: String, completion: @escaping (Result<String, OpenAIError>) -> Void) {
        let prompt = """
        Based on the mood "\(mood)", generate a short, modern, and aesthetic playlist title (2-4 words max). Do not include quotes or extra explanation—just return the title.
        """

        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a music curator who generates catchy playlist titles."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 20,
            "temperature": 0.8
        ]

        sendOpenAIRequest(requestBody: requestBody, completion: completion)
    }

    


}
