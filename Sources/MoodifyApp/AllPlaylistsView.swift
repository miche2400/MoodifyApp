//
//  AllPlaylistsView.swift
//  Moodify
//
//  Created by Michelle Rodriguez on 24/03/2025.
//

import SwiftUI

struct AllPlaylistsView: View {
    @State private var moodSelectionsList: [moodSelections] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // For navigating to a new questionnaire screen
    @State private var showNewPlaylistFlow = false
    
    // Access the global isLoggedIn AppStorage from ContentView
    @AppStorage("UserLoggedIn") private var isLoggedIn: Bool = false
    
    // Add environment dismiss to pop this view when logging out
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // "New Playlist" button at the top
                Button(action: {
                    showNewPlaylistFlow = true
                    forceQuestionnaire = true
                }) {
                    Text("New Playlist")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding()
                // Navigate to your existing ContentView (questionnaire flow)
                .navigationDestination(isPresented: $showNewPlaylistFlow) {
                    ContentView()
                        .navigationBarBackButtonHidden(true)
                }
                
                Group {
                    if isLoading {
                        ProgressView("Loading playlists...")
                            .scaleEffect(1.2)
                    } else if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        // Display the user’s playlists in a List
                        List(moodSelectionsList, id: \.id) { selection in
                            NavigationLink(destination: PlaylistRecommendationView(playlistID: selection.playlist_id)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(selection.mood)
                                        .font(.headline)
                                    Text("Tap to open")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Your Playlists")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                // Logout button in the top-right
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") {
                        logoutFromSpotify()
                    }
                }
            }
            .onAppear {
                fetchMoodSelections()
            }
        }
    }
    
    // MARK: - Fetch Mood Selections
    private func fetchMoodSelections() {
        isLoading = true
        errorMessage = nil
        
        // Query moodSelections for the current Spotify user only.
        SupabaseService.shared.fetchMoodSelections { fetched in
            DispatchQueue.main.async {
                self.isLoading = false
                if fetched.isEmpty {
                    self.errorMessage = "No playlists found."
                } else {
                    self.moodSelectionsList = fetched
                }
            }
        }
    }
    
    // MARK: - Logout Logic
    private func logoutFromSpotify() {
        // Remove stored tokens or user states
        UserDefaults.standard.removeObject(forKey: "SpotifyAccessToken")
        UserDefaults.standard.removeObject(forKey: "UserCompletedQuestionnaire")
        
        // Mark user as logged out
        isLoggedIn = false
        
        // Dismiss the current view so that the login view appears
        dismiss()
    }
}
