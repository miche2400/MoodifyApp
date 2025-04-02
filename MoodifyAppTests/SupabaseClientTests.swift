//
//  SupabaseClientTests.swift
//  Moodify
//
//  Created by Michelle Rodriguez on 02/04/2025.
//


import XCTest
@testable import MoodifyApp

final class SupabaseClientTests: XCTestCase {

    func testMoodSelectionStorageFormat() {
        let mood = "Happy"
        let userId = "test_user"
        let playlistId = "123abc"
        let title = "Chill Vibes"

        let expectation = expectation(description: "Store mood selection")

        SupabaseService.shared.storeMoodSelection(spotifyUserID: userId, mood: mood, playlistID: playlistId, title: title) { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure(let error):
                XCTFail("Storage failed: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5)
    }
}
