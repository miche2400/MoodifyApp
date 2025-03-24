//
//  AllPlaylistsView.swift
//  Moodify
//
//  Created by Michelle Rodriguez on 24/03/2025.
//
import SwiftUI

struct AllPlaylistsView: View {
    @State private var moodSelections: [MoodSelection] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading playlists...")
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else {
                List(moodSelections, id: \.id) { selection in
                    VStack(alignment: .leading) {
                        Text(selection.mood)
                            .font(.headline)
                        // If you want to show the Spotify playlist ID as a link, do:
                        Text("Playlist ID: \(selection.playlist_id)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle("Your Playlists")
        .onAppear {
            fetchMoodSelections()
        }
    }

    private func fetchMoodSelections() {
        isLoading = true
        errorMessage = nil

        // Call a new SupabaseService method that fetches from 'moodSelections'
        SupabaseService.shared.fetchUserMoodSelections { fetched in
            DispatchQueue.main.async {
                self.isLoading = false
                if fetched.isEmpty {
                    self.errorMessage = "No playlists found."
                } else {
                    self.moodSelections = fetched
                }
            }
        }
    }
}
