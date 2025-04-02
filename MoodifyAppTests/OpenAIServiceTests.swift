//
//  OpenAIServiceTests.swift
//  MoodifyAppTests
//
//  Created by Michelle Rodriguez on 02/04/2025.
//

// File: OpenAIServiceTests.swift
import XCTest
@testable import MoodifyApp

final class OpenAIServiceTests: XCTestCase {

    func testGeneratePlaylistTitleMocked() async throws {
        // Given
        let mood = "Excited"
        let expectedTitle = "Energised Beats"

        class MockOpenAIService: OpenAIServiceProtocol {
            func generatePlaylistTitle(from mood: String, completion: @escaping (Result<String, OpenAIError>) -> Void) {
                completion(.success("Energised Beats"))
            }
        }

        let service: OpenAIServiceProtocol = MockOpenAIService()

        // When
        let expectation = XCTestExpectation(description: "Wait for playlist title")
        var resultTitle: String?
        service.generatePlaylistTitle(from: mood) { result in
            if case .success(let title) = result {
                resultTitle = title
            }
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5)

        // Then
        XCTAssertEqual(resultTitle, expectedTitle, "Generated playlist title should match the expected mock.")
    }
}
