import UIKit
import XCTest
@testable import Runner

final class RunnerTests: XCTestCase {
    @MainActor func testSystemEditButtonAndTableStayInSync() throws {
        let list = LibraryController(style: .insetGrouped)
        list.loadViewIfNeeded()
        let edit = list.editButtonItem
        let action = try XCTUnwrap(edit.action)
        XCTAssertTrue(UIApplication.shared.sendAction(action, to: edit.target, from: edit, for: nil))
        XCTAssertTrue(list.tableView.isEditing)
        XCTAssertTrue(UIApplication.shared.sendAction(action, to: edit.target, from: edit, for: nil))
        XCTAssertFalse(list.tableView.isEditing)
    }
}
