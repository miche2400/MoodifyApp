//
//  OpenAIClassificationTests.swift
//  Moodify
//
//  Created by Michelle Rodriguez on 02/04/2025.
//

import XCTest
@testable import MoodifyApp

// Extension to expose the private buildPrompt method for testing.
extension OpenAIService {
    func test_buildPrompt(from responses: [Response]) -> String {
        return buildPrompt(from: responses)
    }
}

final class OpenAIClassificationTests: XCTestCase {

    func testBuildPromptFromResponses() {
        let responses = [
            Response(question: "How do you feel today?", answer: "I feel calm and relaxed."),
            Response(question: "How was your sleep?", answer: "Pretty good.")
        ]
        let service = OpenAIService.shared
        let prompt = service.test_buildPrompt(from: responses)
        
        // Check that the prompt contains the expected header.
        XCTAssertTrue(prompt.contains("Determine the user’s overall mood"), "Prompt should start with mood determination instructions.")
        // Also verify it contains the questions.
        XCTAssertTrue(prompt.contains("1) Question:"), "Prompt should include the first question.")
    }
}
