//
//  PlaylistRecommendationView.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 20/02/2025.
//

import SwiftUI
import WebKit
import Supabase

struct PlaylistRecommendationView: View {
    @State var userResponses: [Response]
    @State private var recommendedPlaylist: [String] = []
    @State private var playlistURL: String? = nil
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
            } else if let playlistURL = playlistURL,
                      let playlistID = extractSpotifyPlaylistID(from: playlistURL) {
                // **Embed Spotify Playlist**
                SpotifyEmbedView(playlistID: playlistID)
                    .frame(height: 400)  // Adjust height as needed

                Button("Open in Spotify App") {
                    openInSpotifyApp(playlistID: playlistID)
                }
                .padding()
            }
        }
        .onAppear {
            fetchLatestResponses()
        }
    }

    // MARK: - Fetch Latest User Responses
    private func fetchLatestResponses() {
        isLoading = true
        errorMessage = nil

        SupabaseService.shared.fetchLatestResponses { responses in
            DispatchQueue.main.async {
                if responses.isEmpty {
                    self.errorMessage = "No responses found. Please complete the questionnaire."
                    self.isLoading = false
                } else {
                    self.userResponses = responses
                    print("[DEBUG] User responses retrieved: \(responses)")
                    self.fetchPlaylistRecommendation()
                }
            }
        }
    }

    // MARK: - Fetch Playlist Recommendation from OpenAI
    func fetchPlaylistRecommendation() {
        OpenAIService.shared.generatePlaylist(from: userResponses) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let playlistData):
                    let parsedPlaylist = playlistData
                        .components(separatedBy: "\n")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

                    if parsedPlaylist.isEmpty {
                        self.errorMessage = "OpenAI returned an invalid playlist."
                    } else {
                        self.recommendedPlaylist = parsedPlaylist
                        print("[DEBUG] Playlist generated: \(parsedPlaylist)")
                        self.createSpotifyPlaylist()
                    }

                case .failure(let error):
                    self.errorMessage = "Failed to get playlist: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Create Playlist on Spotify and Store in Supabase
    private func createSpotifyPlaylist() {
        let detectedMood = "Detected Mood"  // Replace with actual AI-based mood if needed

        // `createAndSavePlaylist` should handle:
        // 1) Creating the playlist on Spotify
        // 2) Storing the mood + playlist in Supabase (using the Spotify user ID)
        SpotifyAPIService.shared.createAndSavePlaylist(mood: detectedMood,
                                                       songNames: recommendedPlaylist) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let returnedPlaylistURL):
                    self.playlistURL = returnedPlaylistURL  // e.g. "https://open.spotify.com/playlist/..."
                    print("[DEBUG] Spotify Playlist URL received: \(returnedPlaylistURL)")

                case .failure(let error):
                    print("[ERROR] Failed to save playlist: \(error.localizedDescription)")
                    self.errorMessage = "Failed to save playlist to Spotify."
                }
            }
        }
    }

    // MARK: - Open Playlist in Spotify App
    private func openInSpotifyApp(playlistID: String) {
        guard let url = URL(string: "spotify://playlist/\(playlistID)") else {
            print("[ERROR] Invalid playlist URL: \(playlistID)")
            return
        }
        UIApplication.shared.open(url)
    }

    // MARK: - Extract Spotify Playlist ID
    private func extractSpotifyPlaylistID(from url: String) -> String? {
        let components = url.components(separatedBy: "/")
        if let lastComponent = components.last?.components(separatedBy: "?").first {
            print("[DEBUG] Extracted Playlist ID: \(lastComponent)")
            return lastComponent
        }
        print("[ERROR] Failed to extract Spotify Playlist ID from URL: \(url)")
        return nil
    }
}
