//
//  ContentView.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 17/12/2024.
//
import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn: Bool = false
    @State private var userHasPlaylists: Bool = false
    @State private var navigateToPlaylist: Bool = false
    @State private var playlistID: String?
    @State private var playlistTitle: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoggedIn {
                    // Show AllPlaylistsView when the user is logged in.
                    AllPlaylistsView()
                } else {
                    // Show SpotifyLoginView when the user is not logged in.
                    SpotifyLoginView(
                        isLoggedIn: .constant(false),
                        navigateToQuestionnaire: .constant(false)
                    )
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToPlaylist) {
                if let playlistID = playlistID {
                    PlaylistRecommendationView(playlistID: playlistID, playlistTitle: playlistTitle)
                } else {
                    Text("Failed to load playlist.")
                }
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "Something went wrong."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                print("[DEBUG] ContentView appeared. Checking user session...")
                validateUserSession()
            }
            .onChange(of: isLoggedIn, initial: false) { oldValue, newValue in
                if !oldValue && newValue {
                    print("[DEBUG] User logged in. Checking if user has playlists.")
                    checkStoredPlaylists()
                }
            }
        }
    }
    
    // Validate Spotify Session without showing a progress view.
    private func validateUserSession() {
        if let token = SpotifyAuthManager.shared.getAccessToken(), !token.isEmpty {
            print("[DEBUG] Found existing Spotify token.")
            Task {
                let success = await SupabaseService.shared.loginWithSpotify(token: token)
                DispatchQueue.main.async {
                    self.isLoggedIn = success
                }
            }
        } else {
            print("[DEBUG] No valid Spotify token found. Showing login screen.")
            DispatchQueue.main.async {
                self.isLoggedIn = false
            }
        }
    }
    
    // Check if the user has stored playlists.
    private func checkStoredPlaylists() {
        SupabaseService.shared.fetchMoodSelections { fetched in
            DispatchQueue.main.async {
                self.userHasPlaylists = !fetched.isEmpty
            }
        }
    }
}
