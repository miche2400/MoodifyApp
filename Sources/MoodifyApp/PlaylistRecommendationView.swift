//
//  PlaylistRecommendationView.swift
//  Moodify
//
//  Created by Michelle Rodriguez on 20/02/2025.
//
 
import SwiftUI
import Supabase

struct PlaylistRecommendationView: View {
    
    
    @State var userResponses: [Response]
    @State private var recommendedPlaylist: [String] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var lastAPICallTime: Date = Date.distantPast


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
                List(recommendedPlaylist, id: \.self) { song in
                    Text(song)
                }
            }
            
            Button("Generate Again") {
                fetchPlaylistRecommendation()
            }
            .padding()
        }
        .onAppear {
            fetchLatestResponses()
        }
    }
    
    // MARK: - Fetch Latest User Responses from Supabase
    private func fetchLatestResponses() {
        isLoading = true
        errorMessage = nil

        SupabaseService.shared.fetchLatestResponses { responses in
            DispatchQueue.main.async {
                if responses.isEmpty {
                    self.errorMessage = "No responses found. Please complete the questionnaire."
                    self.isLoading = false
                } else {
                    if responses == self.userResponses {
                        print("[DEBUG] Using cached responses. Skipping OpenAI API call.")
                        self.isLoading = false
                        return
                    }
                    
                    self.userResponses = responses
                    self.fetchPlaylistRecommendation()
                }
            }
        }
    }


    // MARK: - Fetch Playlist Recommendation from OpenAI
    func fetchPlaylistRecommendation(retryCount: Int = 0) {
        let minInterval: TimeInterval = 120 // 2 minutes delay before API call
        
        if Date().timeIntervalSince(lastAPICallTime) < minInterval {
            print("[DEBUG] Skipping API call: Too soon after last request.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.fetchPlaylistRecommendation(retryCount: retryCount + 1)
            }
            return
        }

        lastAPICallTime = Date() // Update timestamp to prevent spam

        guard !userResponses.isEmpty else {
            DispatchQueue.main.async {
                self.errorMessage = "No user responses available."
            }
            return
        }

        isLoading = true

        OpenAIService.shared.generatePlaylist(from: userResponses) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let playlist):
                    let parsedPlaylist = playlist
                        .components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    
                    if parsedPlaylist.isEmpty {
                        print("[ERROR] OpenAI response did not contain valid song data.")
                        self.errorMessage = "OpenAI returned an invalid playlist. Please try again."
                    } else {
                        self.recommendedPlaylist = parsedPlaylist
                    }

                case .failure(let error):
                    print("[ERROR] OpenAI API request failed: \(error.localizedDescription)")

                    if case .rateLimited = error {
                        print("[DEBUG] Rate limited. Showing error.")
                        self.errorMessage = "Too many requests. Please wait and try again later."
                    } else {
                        self.errorMessage = "Failed to get playlist: \(error.localizedDescription)"
                    }
                }
            }
        }
    }


}
