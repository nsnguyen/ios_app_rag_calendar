import XCTest

final class OnboardingUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("--reset-onboarding")
        app.launch()
    }

    func testOnboardingFlowCompletes() throws {
        // Welcome step
        XCTAssertTrue(app.staticTexts["Welcome to Planner"].waitForExistence(timeout: 5))
        app.buttons["Get Started"].tap()

        // Theme selection step
        XCTAssertTrue(app.staticTexts["Choose Your Style"].waitForExistence(timeout: 5))
        app.buttons["Continue"].tap()

        // Calendar permission step
        XCTAssertTrue(app.staticTexts["Calendar Access"].waitForExistence(timeout: 5))
        app.buttons["Maybe Later"].tap()

        // Siri step
        XCTAssertTrue(app.staticTexts["Siri Integration"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        // Should show main tab view
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
    }

    func testCanSelectThemeDuringOnboarding() throws {
        XCTAssertTrue(app.staticTexts["Welcome to Planner"].waitForExistence(timeout: 5))
        app.buttons["Get Started"].tap()

        XCTAssertTrue(app.staticTexts["Choose Your Style"].waitForExistence(timeout: 5))

        // Tap on a theme option
        if app.staticTexts["Bold"].exists {
            app.staticTexts["Bold"].tap()
        }

        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Calendar Access"].waitForExistence(timeout: 5))
    }
}
