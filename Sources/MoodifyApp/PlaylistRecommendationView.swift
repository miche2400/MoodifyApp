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
    let playlistID: String  
    let playlistTitle: String

    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var showAllPlaylists = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(gradient: Gradient(colors: [.black.opacity(0.9), .blue.opacity(0.7)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Display the AI-generated title instead of a static title
                    Text(playlistTitle)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.clear)
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .mask(
                                Text(playlistTitle)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                            )
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)

                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        SpotifyEmbedView(playlistID: playlistID)
                            .frame(height: 400)

                        Button(action: {
                            openInSpotifyApp(playlistID)
                        }) {
                            Text("Open in Spotify")
                                .fontWeight(.semibold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(LinearGradient(colors: [.purple, .blue],
                                                           startPoint: .leading,
                                                           endPoint: .trailing))
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showAllPlaylists = true
                    } label: {
                        Label("All Playlists", systemImage: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationDestination(isPresented: $showAllPlaylists) {
                AllPlaylistsView()
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    isLoading = false
                }
            }
        }
    }

    // MARK: - Spotify URL Handling
    private func openInSpotifyApp(_ playlistID: String) {
        let appURL = URL(string: "spotify://playlist/\(playlistID)")!
        let webURL = URL(string: "https://open.spotify.com/playlist/\(playlistID)")!

        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }
}
