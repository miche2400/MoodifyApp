// AllPlaylistsView.swift
// Moodify
// Created by Michelle Rodriguez on 24/03/2025.

import SwiftUI
import Foundation

struct PlaylistRoute: Identifiable, Equatable, Hashable {
    let id: String
    let playlistTitle: String
}

struct AllPlaylistsView: View {
    @State private var showQuestionnaire = false
    @State private var selectedPlaylistRoute: PlaylistRoute? = nil
    @State private var moodSelectionsList: [moodSelections] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    @AppStorage("UserLoggedIn") private var isLoggedIn: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.9), Color.blue.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header container with gradient overlay, title, and logout button
                    HStack {
                        Text("Your Playlists")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.white)
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .mask(
                                    Text("Your Playlists")
                                        .font(.largeTitle.weight(.bold))
                                )
                            )
                        Spacer()
                        Button("Logout") {
                            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                                delegate.logoutUser()
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.purple)
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .onAppear {
                        fetchPlaylists()
                    }
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                        Spacer()
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                // The list is reversed so that the last created appears first.
                                ForEach(Array(moodSelectionsList.enumerated()), id: \.1.id) { index, selection in
                                    PlaylistCard(
                                        title: selection.title.isEmpty ? "Untitled Playlist" : selection.title.replacingOccurrences(of: "\\\"", with: ""),
                                        playlistID: selection.playlist_id,
                                        delay: Double(index) * 0.05
                                    ) {
                                        selectedPlaylistRoute = PlaylistRoute(
                                            id: selection.playlist_id,
                                            playlistTitle: selection.title.isEmpty ? "Untitled Playlist" : selection.title.replacingOccurrences(of: "\\\"", with: "")
                                        )
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.bottom, 100)
                        }
                    }
                }
                .navigationBarBackButtonHidden(true)
                
                // Floating plus button at bottom right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showQuestionnaire = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.purple)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
                        }
                        .padding()
                    }
                }
            }
            .navigationDestination(item: $selectedPlaylistRoute) { route in
                PlaylistRecommendationView(playlistID: route.id, playlistTitle: route.playlistTitle)
            }
            .fullScreenCover(isPresented: $showQuestionnaire) {
                QuestionnaireView { playlistID in
                    showQuestionnaire = false
                    // Optionally, you may retrieve the title from moodSelectionsList here if needed.
                    selectedPlaylistRoute = PlaylistRoute(id: playlistID, playlistTitle: "New Playlist")
                    fetchMoodSelections()
                }
                .navigationBarBackButtonHidden(true)
            }
            .onAppear {
                fetchMoodSelections()
            }
        }
    }
    
    // Fetch user-specific playlists using SupabaseService
    private func fetchPlaylists() {
        SupabaseService.shared.fetchUserPlaylists { fetchedPlaylists in
            DispatchQueue.main.async {
                // Reverse list: the last created playlist appears first.
                self.moodSelectionsList = fetchedPlaylists.reversed()
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Fetch Mood Selections from Supabase
    private func fetchMoodSelections() {
        isLoading = true
        errorMessage = nil
        SupabaseService.shared.fetchMoodSelections { fetched in
            DispatchQueue.main.async {
                self.isLoading = false
                if fetched.isEmpty {
                    self.errorMessage = "No playlists found."
                } else {
                    // Reverse the order so that the latest is at the beginning
                    self.moodSelectionsList = fetched.reversed()
                }
            }
        }
    }
    
}
