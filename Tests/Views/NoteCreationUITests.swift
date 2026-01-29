import XCTest

final class NoteCreationUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("--skip-onboarding")
        app.launch()
    }

    func testCreateNewNote() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["Notes"].tap()
        XCTAssertTrue(app.navigationBars["Notes"].waitForExistence(timeout: 3))

        // Tap the plus button to create a new note
        let addButton = app.buttons["plus"].firstMatch
        if addButton.exists {
            addButton.tap()

            // Verify note editor appears
            XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3))

            // Type a title
            let titleField = app.textFields.firstMatch
            if titleField.exists {
                titleField.tap()
                titleField.typeText("Test Note")
            }

            // Tap Done
            if app.buttons["Done"].exists {
                app.buttons["Done"].tap()
            }
        }
    }
}
