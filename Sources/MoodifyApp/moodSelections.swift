//
//  MoodSelection.swift
//  Moodify
//
//  Created by Michelle Rodriguez on 17/03/2025.
//

import Foundation

struct moodSelections: Codable, Equatable {
    let id: Int?
    let created_at: String?
    let user_id: String  // Updated from UUID to String
    let mood: String
    let playlist_id: String
    let title: String  

    static func == (lhs: moodSelections, rhs: moodSelections) -> Bool {
        return lhs.id == rhs.id &&
               lhs.user_id == rhs.user_id &&
               lhs.mood == rhs.mood &&
               lhs.playlist_id == rhs.playlist_id &&
               lhs.title == rhs.title
    }
}
