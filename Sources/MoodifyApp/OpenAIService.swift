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
}

class OpenAIService {
    static let shared = OpenAIService()
    
    // Pull the API key from Info.plist
    private let openAIKey: String? = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String
    
    
    //  Main function: Takes the user's question/answer data, calls the Chat Completion endpoint, and returns a mood (Happy, Sad, Relaxed, Energetic, or Sleepy).
    func classifyMood(
        responses: [Response],
        completion: @escaping (Result<String, OpenAIError>) -> Void
    ) {
        // Convert user answers into a single prompt
        let userPrompt = buildPrompt(from: responses)
        
        // Create a dictionary for the Chat Completion request body
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo", // or "gpt-4"
            "messages": [
                [
                    "role": "system",
                    "content": "You are a helpful assistant that determines a user's mood from a list of statements."
                ],
                [
                    "role": "user",
                    "content": userPrompt
                ]
            ],
            "max_tokens": 50,
            "temperature": 0.7
        ]
        
        // Convert the dictionary to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(.decodingFailed))
            return
        }
        
        // Check for API key
        guard let apiKey = openAIKey, !apiKey.isEmpty else {
            completion(.failure(.missingAPIKey))
            return
        }
        
        // Build the URL and request
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        // Make the network call
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network-level error
            if let error = error {
                completion(.failure(.requestFailed(error.localizedDescription)))
                return
            }
            // Ensure we got a 200 status, plus data
            guard
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200,
                let data = data
            else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                completion(.failure(.requestFailed("Status code: \(status)")))
                return
            }
            
            // Decode the JSON into our OpenAIChatResponse
            do {
                let decodedResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
                
                // 8) Extract the content from the first choice
                if let answerText = decodedResponse.choices.first?.message.content {
                    // Parse the answer to find a recognized mood
                    let detectedMood = self.parseMood(from: answerText)
                    if detectedMood.isEmpty {
                        completion(.failure(.noMoodDetected))
                    } else {
                        completion(.success(detectedMood))
                    }
                } else {
                    completion(.failure(.decodingFailed))
                }
            } catch {
                completion(.failure(.decodingFailed))
            }
        }.resume()
    }
    
    // MARK: - Prompt Construction
    // Builds a text prompt from the user's [Response].
    
    private func buildPrompt(from responses: [Response]) -> String {
        /*
         Example output:
         "Determine the user’s overall mood from these statements:
           1) Question: "I feel calm." / Answer: "Agree"
           2) Question: "I feel tired." / Answer: "Strongly Agree"
         Please give me one of these moods: Happy, Sad, Relaxed, Energetic, or Sleepy."
        */
        var result = "Determine the user’s overall mood from these statements:\n"
        for (index, resp) in responses.enumerated() {
            result += "\(index + 1)) Question: \"\(resp.question)\"\n   Answer: \"\(resp.answer)\"\n\n"
        }
        result += "Please give me one of these moods: Happy, Sad, Relaxed, Energetic, or Sleepy.\n"
        return result
    }
    
    // MARK: - Mood Parsing
    // Searches for one of the known moods in the AI's answer
 
    private func parseMood(from answer: String) -> String {
        let possibleMoods = ["happy", "sad", "relaxed", "energetic", "sleepy"]
        let lowercasedAnswer = answer.lowercased()
        
        for mood in possibleMoods {
            if lowercasedAnswer.contains(mood) {
                // Return the capitalized version (e.g. "Happy")
                return mood.capitalized
            }
        }
        return ""
    }
    
    // MARK: - Decoding Model for Chat Completions
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
