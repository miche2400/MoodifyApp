//
//  PlaylistCard.swift
//  Moodify
//
//  Created by Michelle Rodriguez on 26/03/2025.
//

//UI of the AllPlaylistsView

import SwiftUI

struct PlaylistCard: View {
    let title: String
    let playlistID: String
    let delay: Double
    let onTap: () -> Void

    @State private var isVisible = false

    var body: some View {
        Text(title.replacingOccurrences(of: "\"", with: ""))
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.4), radius: 14, x: 0, y: 8)
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.9)
            .animation(.easeOut.delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
    }
}
