import Foundation
import XCTest
@testable import LedgerlyApp

@MainActor
final class FeedbackPersistenceTests: XCTestCase {
    func testSavedFeedbackSurvivesNewControllerAndRepositorySessions() async throws {
        let url = try feedbackURL()
        let firstSession = FeedbackController(repository: LocalFeedbackRepository(fileURL: url))
        await firstSession.present()
        XCTAssertEqual(firstSession.notes, "")
        XCTAssertTrue(firstSession.canSave)
        let notes = "Improve the charts.\nFix the date picker.\nIdeas: café receipts ☕️"
        firstSession.notes = notes
        await firstSession.save()
        XCTAssertFalse(firstSession.isPresented)
        XCTAssertNil(firstSession.errorMessage)

        let nextSession = FeedbackController(repository: LocalFeedbackRepository(fileURL: url))
        await nextSession.present()
        XCTAssertEqual(nextSession.notes, notes)
        nextSession.notes = "Remaining idea: improve the charts."
        await nextSession.save()

        let reopened = LocalFeedbackRepository(fileURL: url)
        let saved = try await reopened.load()
        XCTAssertEqual(saved, "Remaining idea: improve the charts.")
    }

    func testCancelPreservesSavedNotesAndEmptyNotesCanBeSaved() async throws {
        let url = try feedbackURL()
        let repository = LocalFeedbackRepository(fileURL: url)
        try await repository.save("Original thoughts")
        let controller = FeedbackController(repository: repository)
        await controller.present()
        controller.notes = "Unsaved changes"
        controller.cancel()
        await controller.present()
        XCTAssertEqual(controller.notes, "Original thoughts")
        controller.notes = ""
        await controller.save()
        let saved = try await LocalFeedbackRepository(fileURL: url).load()
        XCTAssertEqual(saved, "")
    }

    func testUnreadableFeedbackIsNotTreatedAsAnEmptyNotebook() async throws {
        let url = try feedbackURL()
        let invalidText = Data([0xFF, 0xFE, 0xFF])
        try invalidText.write(to: url)
        let controller = FeedbackController(repository: LocalFeedbackRepository(fileURL: url))
        await controller.present()
        XCTAssertNotNil(controller.errorMessage)
        XCTAssertFalse(controller.canSave)
        controller.notes = "Do not overwrite unreadable data"
        await controller.save()
        XCTAssertEqual(try Data(contentsOf: url), invalidText)
    }

    func testFailedSaveKeepsEditorOpenAndRetainsDraft() async throws {
        let url = try feedbackURL()
        let controller = FeedbackController(repository: LocalFeedbackRepository(fileURL: url))
        await controller.present()
        controller.notes = "Keep this draft on failure"
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        await controller.save()
        XCTAssertTrue(controller.isPresented)
        XCTAssertEqual(controller.notes, "Keep this draft on failure")
        XCTAssertNotNil(controller.errorMessage)
        XCTAssertFalse(controller.isSaving)
        XCTAssertTrue(controller.canSave)
    }

    private func feedbackURL() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try FileManager.default.removeItem(at: directory) }
        return directory.appendingPathComponent("feedback.txt")
    }
}
