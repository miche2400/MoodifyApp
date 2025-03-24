//
//  SpotifyEmbedView.swift
//  Moodify
//
//  Created by Michelle Rodriguez on 18/03/2025.
//

import SwiftUI
import WebKit

struct SpotifyEmbedView: UIViewRepresentable {
    let playlistID: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.configuration.allowsInlineMediaPlayback = true
        webView.allowsBackForwardNavigationGestures = true // Enables interactions
        
        if let url = URL(string: "https://open.spotify.com/embed/playlist/\(playlistID)") {
            webView.load(URLRequest(url: url))
        } else {
            print("[ERROR] Invalid Spotify Playlist URL")
        }
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: "https://open.spotify.com/embed/playlist/\(playlistID)") {
            uiView.load(URLRequest(url: url))
        }
    }

}
