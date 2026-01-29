import XCTest

final class SearchUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("--skip-onboarding")
        app.launch()
    }

    func testSearchTabShowsSearchField() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["Search"].tap()
        XCTAssertTrue(app.navigationBars["Search"].waitForExistence(timeout: 3))

        // Search field should exist
        let searchField = app.textFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
    }

    func testSearchEmptyState() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["Search"].tap()

        // Should show the empty state
        XCTAssertTrue(app.staticTexts["Semantic Search"].waitForExistence(timeout: 3))
    }

    func testSearchWithQuery() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["Search"].tap()

        let searchField = app.textFields.firstMatch
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()
            searchField.typeText("meetings about design")
            // Submit search
            app.keyboards.buttons["return"].tap()
        }
    }
}
