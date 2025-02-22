//
//  PlaylistRecommendationView.swift
//  Moodify
//
//  Created by Michelle Rodriguez on 20/02/2025.
//

import SwiftUI
import OpenAI
import Supabase

struct PlaylistRecommendationView: View {
    let userResponses: [Response]
    @State private var recommendedPlaylist: [String] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            Text("Your Personalized Playlist")
                .font(.largeTitle)
                .bold()
                .padding()
            
            if isLoading {
                ProgressView("Generating your playlist...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.2)
                    .padding()
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else {
                List(recommendedPlaylist, id: \ .self) { song in
                    Text(song)
                }
            }
            
            Button("Generate Again") {
                fetchPlaylistRecommendation()
            }
            .padding()
        }
        .onAppear {
            fetchPlaylistRecommendation()
        }
    }
    
    private func fetchPlaylistRecommendation() {
        isLoading = true
        errorMessage = nil
        
        let userMood = analyzeMood(from: userResponses)
        let prompt = "Based on the user's mood: \(userMood), recommend a playlist with 5 songs."
        
        OpenAIService.shared.getAIRecommendation(for: prompt) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let songs):
                    self.recommendedPlaylist = songs
                case .failure(let error):
                    self.errorMessage = "Failed to get playlist: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func analyzeMood(from responses: [Response]) -> String {
        let positiveResponses = ["Agree", "Strongly Agree"]
        let negativeResponses = ["Disagree", "Strongly Disagree"]
        
        let positiveCount = responses.filter { positiveResponses.contains($0.answer) }.count
        let negativeCount = responses.filter { negativeResponses.contains($0.answer) }.count
        
        if positiveCount > negativeCount {
            return "Happy and Energetic"
        } else if negativeCount > positiveCount {
            return "Calm and Relaxing"
        } else {
            return "Neutral"
        }
    }
}
