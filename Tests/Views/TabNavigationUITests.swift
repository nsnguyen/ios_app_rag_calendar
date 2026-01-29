import XCTest

final class TabNavigationUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("--skip-onboarding")
        app.launch()
    }

    func testAllTabsAreVisible() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        XCTAssertTrue(tabBar.buttons["Today"].exists)
        XCTAssertTrue(tabBar.buttons["Notes"].exists)
        XCTAssertTrue(tabBar.buttons["Search"].exists)
        XCTAssertTrue(tabBar.buttons["People"].exists)
    }

    func testNavigateBetweenTabs() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["Notes"].tap()
        XCTAssertTrue(app.navigationBars["Notes"].waitForExistence(timeout: 3))

        tabBar.buttons["Search"].tap()
        XCTAssertTrue(app.navigationBars["Search"].waitForExistence(timeout: 3))

        tabBar.buttons["People"].tap()
        XCTAssertTrue(app.navigationBars["People"].waitForExistence(timeout: 3))

        tabBar.buttons["Today"].tap()
        // Today tab uses a date string as nav title, so check for tab selection
        XCTAssertTrue(tabBar.buttons["Today"].isSelected)
    }
}
