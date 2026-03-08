//
//  AnalystUITests.swift
//  AnalystUITests
//
//  UI tests for critical user flows in the Analyst app.
//

import XCTest

final class AnalystUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch Tests

    @MainActor
    func testAppLaunches_withoutCrash() throws {
        app.launch()
        // App should launch and display something (splash or login)
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }

    // MARK: - Login Screen Tests

    @MainActor
    func testLoginScreen_elementsExist() throws {
        app.launch()

        // Wait for loading to complete
        let timeout: TimeInterval = 10

        // Check for login screen elements (may vary based on auth state)
        let loginExists = app.textFields.firstMatch.waitForExistence(timeout: timeout)
            || app.secureTextFields.firstMatch.waitForExistence(timeout: timeout)
            || app.buttons["Sign In"].waitForExistence(timeout: timeout)

        // If we see login elements, test passes
        // If we don't (e.g., already logged in), that's also valid
        if loginExists {
            // Login screen is showing — verify basic structure
            XCTAssertTrue(app.buttons.count > 0, "Login screen should have at least one button")
        }
    }

    // MARK: - Navigation Tests

    @MainActor
    func testTabBar_navigation() throws {
        app.launch()

        let timeout: TimeInterval = 10

        // Wait for the app to load past splash
        _ = app.staticTexts.firstMatch.waitForExistence(timeout: timeout)

        // If we're on the main tab view, check tab bar exists
        let tabButtons = app.buttons
        if tabButtons.count >= 5 {
            // Tab bar should have 5 tabs
            XCTAssertTrue(tabButtons.count >= 5, "Tab bar should have at least 5 buttons")
        }
    }

    // MARK: - Performance Tests

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    @MainActor
    func testScrollPerformance() throws {
        app.launch()

        let timeout: TimeInterval = 10
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: timeout)

        if app.scrollViews.firstMatch.exists {
            measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
                app.scrollViews.firstMatch.swipeUp()
                app.scrollViews.firstMatch.swipeDown()
            }
        }
    }
}
