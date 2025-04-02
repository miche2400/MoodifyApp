//
//  MoodifyAppTests.swift
//  MoodifyAppTests
//
//  Created by Michelle Rodriguez on 02/04/2025.
//


import XCTest
@testable import MoodifyApp

final class MoodifyAppTests: XCTestCase {
    
    func testResponseEquatability() {
        let response1 = Response(question: "How are you?", answer: "Happy")
        let response2 = Response(question: "How are you?", answer: "Happy")
        let response3 = Response(question: "Different question?", answer: "Sad")
        
        XCTAssertEqual(response1, response2)
        XCTAssertNotEqual(response1, response3)
    }

    func testMoodSelectionsDecoding() throws {
        let jsonString = """
        {
            "id": 1,
            "created_at": "2025-03-17T12:00:00Z",
            "user_id": "user123",
            "mood": "Happy",
            "playlist_id": "playlist123",
            "title": "Chill Vibes"
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let selection = try decoder.decode(moodSelections.self, from: jsonData)
        
        XCTAssertEqual(selection.user_id, "user123")
        XCTAssertEqual(selection.mood, "Happy")
        XCTAssertEqual(selection.title, "Chill Vibes")
    }
}
