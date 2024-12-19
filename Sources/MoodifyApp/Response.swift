//
//  Response.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 18/12/2024.
//

import Foundation

struct Response: Encodable {
    var likert_scale: Int
    var multiple_choice: String
    var timestamp: String
}
