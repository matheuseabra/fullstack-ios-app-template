//
//  AppTemplateUITests.swift
//  AppTemplateUITests
//
//  Created by Matheus Seabra on 03/03/26.
//

import XCTest

final class AppTemplateUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCreateTaskAppearsInCalendarDaySheet() throws {
        let app = launchAppForTaskCRUD()
        let taskTitle = "UI Create \(UUID().uuidString.prefix(6))"

        createTask(app: app, title: taskTitle)

        app.buttons["tasksTab.listButton"].tap()
        app.buttons["calendar.day.today"].tap()
        XCTAssertTrue(app.staticTexts[taskTitle].waitForExistence(timeout: 5))
    }

    @MainActor
    func testOpenTaskDetailFromDashboard() throws {
        let app = launchAppForTaskCRUD()
        let taskTitle = "UI Detail \(UUID().uuidString.prefix(6))"

        createTask(app: app, title: taskTitle)

        let taskTitleText = app.staticTexts[taskTitle]
        XCTAssertTrue(taskTitleText.waitForExistence(timeout: 5))
        taskTitleText.tap()

        XCTAssertTrue(app.buttons["taskDetail.editButton"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testEditAndDeleteTaskFromDetail() throws {
        let app = launchAppForTaskCRUD()
        let initialTitle = "UI Edit \(UUID().uuidString.prefix(6))"
        let updatedTitle = "UI Updated \(UUID().uuidString.prefix(6))"

        createTask(app: app, title: initialTitle)

        let initialTaskText = app.staticTexts[initialTitle]
        XCTAssertTrue(initialTaskText.waitForExistence(timeout: 5))
        initialTaskText.tap()

        let editButton = app.buttons["taskDetail.editButton"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        let titleField = app.textFields["taskForm.titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.clearAndTypeText(updatedTitle)
        titleField.typeText("\n")

        let submitButton = app.buttons["taskForm.submitButton"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 5))
        if !submitButton.isHittable {
            app.swipeUp()
        }
        submitButton.tap()

        XCTAssertTrue(app.staticTexts[updatedTitle].waitForExistence(timeout: 5))

        let deleteButton = app.buttons["taskDetail.deleteButton"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        let deleteAlert = app.alerts["Delete Task?"]
        XCTAssertTrue(deleteAlert.waitForExistence(timeout: 5))
        deleteAlert.buttons["Delete"].tap()

        XCTAssertFalse(app.staticTexts[updatedTitle].waitForExistence(timeout: 3))
    }

    @MainActor
    func testCompletedTaskDisappearsFromDashboard() throws {
        let app = launchAppForTaskCRUD()
        let taskTitle = "UI Complete \(UUID().uuidString.prefix(6))"

        createTask(app: app, title: taskTitle)

        let taskTitleText = app.staticTexts[taskTitle]
        XCTAssertTrue(taskTitleText.waitForExistence(timeout: 5))
        taskTitleText.tap()

        let toggleStatusButton = app.buttons["taskDetail.toggleStatusButton"]
        XCTAssertTrue(toggleStatusButton.waitForExistence(timeout: 5))
        toggleStatusButton.tap()

        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertFalse(app.staticTexts[taskTitle].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["You have nothing scheduled for today."].waitForExistence(timeout: 5))
    }

    // MARK: - Helpers

    @MainActor
    private func launchAppForTaskCRUD() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-ui-testing-home", "-ui-testing-reset-data"]
        app.launch()

        XCTAssertTrue(app.buttons["tasksTab.addButton"].waitForExistence(timeout: 8))
        return app
    }

    @MainActor
    private func createTask(app: XCUIApplication, title: String) {
        let addButton = app.buttons["tasksTab.addButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let titleField = app.textFields["taskForm.titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText(title)
        titleField.typeText("\n")

        let submitButton = app.buttons["taskForm.submitButton"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 5))
        if !submitButton.isHittable {
            app.swipeUp()
        }
        submitButton.tap()
    }
}

private extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        tap()

        let currentValue = value as? String ?? ""
        if !currentValue.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
            typeText(deleteString)
        }

        typeText(text)
    }
}
