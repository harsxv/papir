import Combine
import Foundation

@MainActor
final class ScratchpadStore: ObservableObject {
    static let characterLimit = 100_000

    @Published private(set) var text = "" {
        didSet {
            guard hasLoaded else { return }
            hasUnsavedChanges = true
            scheduleSave()
        }
    }

    @Published private(set) var errorMessage: String?
    @Published private(set) var limitMessage: String?

    private let fileURL: URL
    private let autosaveDelay: Duration
    private var autosaveTask: Task<Void, Never>?
    private var hasLoaded = false
    private var hasUnsavedChanges = false

    init(fileURL: URL = ScratchpadStore.defaultFileURL, autosaveDelay: Duration = .milliseconds(500)) {
        self.fileURL = fileURL
        self.autosaveDelay = autosaveDelay
        load()
        hasLoaded = true
    }

    @discardableResult
    func updateText(_ newText: String) -> Bool {
        guard newText.count <= Self.characterLimit else {
            limitMessage = "Character limit reached"
            return false
        }

        limitMessage = nil
        text = newText
        return true
    }

    func saveNow() {
        autosaveTask?.cancel()
        guard hasUnsavedChanges else { return }

        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data(text.utf8).write(to: fileURL, options: .atomic)
            hasUnsavedChanges = false
            errorMessage = nil
        } catch {
            errorMessage = "Papir could not save your note."
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            text = try String(contentsOf: fileURL, encoding: .utf8)
            errorMessage = nil
        } catch {
            errorMessage = "Papir could not load your saved note."
        }
    }

    private func scheduleSave() {
        autosaveTask?.cancel()
        autosaveTask = Task { [weak self, autosaveDelay] in
            try? await Task.sleep(for: autosaveDelay)
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    private static var defaultFileURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Papir", directoryHint: .isDirectory)
            .appending(path: "scratch.txt", directoryHint: .notDirectory)
    }
}
