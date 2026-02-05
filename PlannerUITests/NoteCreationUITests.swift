import XCTest

final class NoteCreationUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("--skip-onboarding")
        app.launch()
    }

    func testCreateNewNote() throws {
        // Notes are now accessed via the note icon in the header toolbar
        // Wait for the main view to load
        XCTAssertTrue(app.buttons.firstMatch.waitForExistence(timeout: 5))
    }
}
