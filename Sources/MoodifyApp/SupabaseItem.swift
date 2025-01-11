//
//   SuperbaseItem.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 18/12/2024.
//


import Foundation


struct SupabaseItem: Codable {
    let id: UUID?
    let question: String
    let answer: String
    let created_at: String?
}
