import XCTest
@testable import Papir

@MainActor
final class ScratchpadStoreTests: XCTestCase {
    func testMissingFileStartsEmpty() {
        let location = temporaryFileURL()
        XCTAssertEqual(ScratchpadStore(fileURL: location).text, "")
    }

    func testSaveAndLoad() throws {
        let location = temporaryFileURL()
        let store = ScratchpadStore(fileURL: location)
        store.updateText("A useful scrap of text.")
        store.saveNow()

        XCTAssertEqual(try String(contentsOf: location, encoding: .utf8), "A useful scrap of text.")
        XCTAssertEqual(ScratchpadStore(fileURL: location).text, "A useful scrap of text.")
    }

    func testLoadFailureDoesNotInventContent() throws {
        let location = temporaryFileURL()
        try FileManager.default.createDirectory(
            at: location.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data([0xFF]).write(to: location)

        let store = ScratchpadStore(fileURL: location)
        store.saveNow()

        XCTAssertEqual(store.text, "")
        XCTAssertNotNil(store.errorMessage)
        XCTAssertEqual(try Data(contentsOf: location), Data([0xFF]))
    }

    func testOversizedEditIsRejectedWithoutChangingText() {
        let store = ScratchpadStore(fileURL: temporaryFileURL())
        store.updateText("Keep me")

        XCTAssertFalse(store.updateText(String(repeating: "x", count: ScratchpadStore.characterLimit + 1)))
        XCTAssertEqual(store.text, "Keep me")
        XCTAssertNotNil(store.limitMessage)
    }

    func testShortcutOptionsUseUniqueKeyCodes() {
        XCTAssertEqual(Set(ShortcutOption.allCases.map(\.keyCode)).count, ShortcutOption.allCases.count)
    }

    private func temporaryFileURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return directory.appending(path: "scratch.txt", directoryHint: .notDirectory)
    }
}
