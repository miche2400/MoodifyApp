//
//  Response.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 18/12/2024.
//

import Foundation

struct Response: Codable, Equatable {
    let question: String
    let answer: String

    static func == (lhs: Response, rhs: Response) -> Bool {
        return lhs.question == rhs.question && lhs.answer == rhs.answer
    }
}

