import XCTest

final class ThemePickerUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("--skip-onboarding")
        app.launch()
    }

    func testOpenThemePicker() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        // Open settings via gear icon
        let gearButton = app.buttons["gearshape"].firstMatch
        if gearButton.exists {
            gearButton.tap()

            // Tap Appearance
            if app.staticTexts["Appearance"].waitForExistence(timeout: 3) {
                app.staticTexts["Appearance"].tap()

                // Verify theme options exist
                XCTAssertTrue(app.staticTexts["Choose your style"].waitForExistence(timeout: 3))
            }
        }
    }

    func testThemeOptions() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        let gearButton = app.buttons["gearshape"].firstMatch
        if gearButton.exists {
            gearButton.tap()

            if app.staticTexts["Appearance"].waitForExistence(timeout: 3) {
                app.staticTexts["Appearance"].tap()

                // All 4 theme options should be visible
                XCTAssertTrue(app.staticTexts["Calm"].waitForExistence(timeout: 3))
                XCTAssertTrue(app.staticTexts["Bold"].exists)
                XCTAssertTrue(app.staticTexts["Warm"].exists)
                XCTAssertTrue(app.staticTexts["Minimal"].exists)
            }
        }
    }
}
