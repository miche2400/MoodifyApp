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
    let playlistID: String  // This is passed from ContentView after generating the playlist ID
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    // For programmatic navigation to AllPlaylistsView
    @State private var showAllPlaylists = false

    var body: some View {
        NavigationStack {
            VStack {
                Text("Your Personalized Playlist")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                if isLoading {
                    ProgressView("Loading playlist embed...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.2)
                        .padding()
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    // Embed the Spotify playlist
                    SpotifyEmbedView(playlistID: playlistID)
                        .frame(height: 400)

                    Button("Open in Spotify") {
                        openInSpotifyApp(playlistID)
                    }
                    .padding()
                }
            }
            .navigationBarBackButtonHidden(true) // Hide the default back arrow
            .toolbar {
                // Custom leading toolbar button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showAllPlaylists = true
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("All Playlists")
                        }
                    }
                }
            }
            // iOS 16 style: when showAllPlaylists = true, push AllPlaylistsView
            .navigationDestination(isPresented: $showAllPlaylists) {
                AllPlaylistsView()
            }
            .onAppear {
                // If you want to show a loading spinner until the embed is displayed, set isLoading = true
                // and hide it after some condition. For now, we’ll just set it to false.
                isLoading = false
            }
        }
    }

    // MARK: - Open Playlist in Spotify App
    private func openInSpotifyApp(_ playlistID: String) {
        let spotifyURLString = "spotify://playlist/\(playlistID)"
        if let url = URL(string: spotifyURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let webURL = URL(string: "https://open.spotify.com/playlist/\(playlistID)") {
            // Fallback: open the playlist in Safari if the Spotify app isn’t available
            UIApplication.shared.open(webURL)
        } else {
            print("[ERROR] Unable to construct a valid URL for playlist: \(playlistID)")
        }
    }

}
