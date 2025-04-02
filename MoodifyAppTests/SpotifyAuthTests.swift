//
//  SpotifyAuthTest.swift
//  Moodify
//
//  Created by Michelle Rodriguez on 02/04/2025.
//

import XCTest

final class SpotifyAuthTests: XCTestCase {

    func testAccessTokenStorage() {
        let token = "test_access_token"
        // Use the same key as in the auth manager.
        UserDefaults.standard.set(token, forKey: "SpotifyAccessToken")
        
        let storedToken = UserDefaults.standard.string(forKey: "SpotifyAccessToken")
        XCTAssertEqual(storedToken, token, "Access token should be stored and retrieved correctly.")
    }

    func testTokenExpirationCheck() {
        // Set a future Date for the key used in the auth manager.
        let futureDate = Date().addingTimeInterval(3600)
        UserDefaults.standard.set(futureDate, forKey: "SpotifyTokenExpirationDate")
        
        let expiration = UserDefaults.standard.object(forKey: "SpotifyTokenExpirationDate") as? Date
        XCTAssertNotNil(expiration, "Expiration date should not be nil.")
        if let expiration = expiration {
            XCTAssertTrue(expiration > Date(), "Token should not be expired.")
        }
    }
}
