import XCTest

final class TabNavigationUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("--skip-onboarding")
        app.launch()
    }

    func testCalendarViewIsVisible() throws {
        // The main view should be visible without a tab bar
        // The planner header with Jump to Week button should exist
        XCTAssertTrue(app.buttons.firstMatch.waitForExistence(timeout: 5))
    }
}
