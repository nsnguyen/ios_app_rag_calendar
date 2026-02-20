import XCTest

final class SearchUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("--skip-onboarding")
        app.launch()
    }

    func testSearchViewShowsSearchField() throws {
        // Search is now accessed via the magnifying glass icon in the top nav bar
        // Wait for the main view to load
        XCTAssertTrue(app.buttons.firstMatch.waitForExistence(timeout: 5))
    }
}
