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

    @MainActor func testFilteredSelectionDeletesAndUndoesAsOneCommand() throws {
        let suite = "playground.tests.\(UUID())"
        let storage = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { storage.removePersistentDomain(forName: suite) }
        let list = LibraryController(style: .insetGrouped, storage: storage)
        list.loadViewIfNeeded()
        let original = list.items
        let favorites = original.filter(\.favorite)
        XCTAssertEqual(favorites.count, 2)
        list.toggleFilter()
        list.setSelecting(true)
        XCTAssertTrue(list.tableView.allowsMultipleSelectionDuringEditing)
        for row in favorites.indices {
            list.tableView(list.tableView, didSelectRowAt: IndexPath(row: row, section: 0))
        }
        XCTAssertEqual(list.selectedItems, favorites)
        list.deleteSelection()
        XCTAssertEqual(list.items, original.filter { !$0.favorite })
        XCTAssertFalse(list.tableView.allowsMultipleSelectionDuringEditing)
        XCTAssertFalse(list.isEditing)
        list.undoEdit()
        XCTAssertEqual(list.items, original)
        XCTAssertFalse(list.history.canUndo)
        list.redoEdit()
        XCTAssertEqual(list.items, original.filter { !$0.favorite })
        let reopened = LibraryController(style: .insetGrouped, storage: storage)
        XCTAssertEqual(reopened.items, list.items)
    }

    @MainActor func testSwipeArchiveRestoreOrderAndRedoInvalidation() throws {
        let suite = "playground.tests.\(UUID())"
        let storage = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { storage.removePersistentDomain(forName: suite) }
        let list = LibraryController(style: .insetGrouped, storage: storage)
        list.loadViewIfNeeded()
        let starting = list.items
        let row = IndexPath(row: 1, section: 0)
        let swipe = try XCTUnwrap(list.tableView(list.tableView, trailingSwipeActionsConfigurationForRowAt: row))
        XCTAssertEqual(swipe.actions.map(\.title), ["Archive", "Delete"])
        XCTAssertTrue(swipe.performsFirstActionWithFullSwipe)
        let archive = swipe.actions[0]
        archive.handler(archive, list.view) { XCTAssertTrue($0) }
        XCTAssertFalse(list.scopedItems.contains { $0.id == starting[1].id })
        list.setArchiveScope(true)
        XCTAssertEqual(list.scopedItems.map(\.id), [starting[1].id])
        let restoreSwipe = try XCTUnwrap(list.tableView(list.tableView, trailingSwipeActionsConfigurationForRowAt: IndexPath(row: 0, section: 0)))
        let restore = restoreSwipe.actions[0]
        XCTAssertEqual(restore.title, "Restore")
        restore.handler(restore, list.view) { XCTAssertTrue($0) }
        XCTAssertTrue(list.scopedItems.isEmpty)
        list.undoEdit()
        XCTAssertEqual(list.scopedItems.map(\.id), [starting[1].id])
        list.undoEdit()
        XCTAssertEqual(list.items, starting)
        XCTAssertTrue(list.history.canRedo)
        list.toggleFavorite(starting[0].id)
        XCTAssertFalse(list.history.canRedo)
    }

    @MainActor func testLegacyEntryLoadsAndCancelSelectionKeepsLibrary() throws {
        let suite = "playground.tests.\(UUID())"
        let storage = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { storage.removePersistentDomain(forName: suite) }
        let id = UUID()
        let raw: [[String: Any]] = [["id": id.uuidString, "name": "Old entry", "symbol": "book", "note": "", "favorite": false]]
        storage.set(try JSONSerialization.data(withJSONObject: raw), forKey: "componentstudio.library.v1")
        let list = LibraryController(style: .insetGrouped, storage: storage)
        list.loadViewIfNeeded()
        XCTAssertEqual(list.scopedItems.map(\.id), [id])
        list.setSelecting(true)
        list.tableView(list.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        list.setSelecting(false)
        XCTAssertTrue(list.selectedIDs.isEmpty)
        XCTAssertEqual(list.scopedItems.map(\.id), [id])
        XCTAssertFalse(list.history.canUndo)
    }
}
