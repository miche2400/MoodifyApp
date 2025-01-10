//
//  Response.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 18/12/2024.
//

import Foundation

struct Response: Codable {
    let likert_scale: Int
    let multiple_choice: String
    let timestamp: String
}
