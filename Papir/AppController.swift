import AppKit
import Carbon
import SwiftUI

extension Notification.Name {
    static let focusScratchpad = Notification.Name("focusScratchpad")
    static let shortcutDidChange = Notification.Name("shortcutDidChange")
}

enum ShortcutOption: String, CaseIterable, Identifiable {
    case controlOptionT
    case controlOptionN
    case controlOptionP
    case controlOptionS

    static let defaultValue = ShortcutOption.controlOptionT

    var id: String { rawValue }
    var label: String { "Control–Option–\(key)" }

    var keyCode: UInt32 {
        switch self {
        case .controlOptionT: UInt32(kVK_ANSI_T)
        case .controlOptionN: UInt32(kVK_ANSI_N)
        case .controlOptionP: UInt32(kVK_ANSI_P)
        case .controlOptionS: UInt32(kVK_ANSI_S)
        }
    }

    private var key: String {
        switch self {
        case .controlOptionT: "T"
        case .controlOptionN: "N"
        case .controlOptionP: "P"
        case .controlOptionS: "S"
        }
    }
}

@MainActor
final class AppController: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let store = ScratchpadStore()
    private let attachmentState = AttachmentState()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
    private var editorController: NSHostingController<ScratchpadView>?
    private var floatingPanel: NSPanel?
    private var hotKey: EventHotKeyRef?
    private var hotKeyHandler: EventHandlerRef?
    private var currentShortcut: ShortcutOption?
    private var shortcutObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "square.and.pencil", accessibilityDescription: "Papir")
        item.button?.target = self
        item.button?.action = #selector(togglePopover)
        statusItem = item

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 360, height: 280)
        let editorController = NSHostingController(rootView: ScratchpadView(
            store: store,
            attachmentState: attachmentState,
            toggleAttachment: { [weak self] in self?.toggleAttachment() }
        ))
        self.editorController = editorController
        popover.contentViewController = editorController

        installHotKeyHandler()
        registerSelectedHotKey()
        shortcutObserver = NotificationCenter.default.addObserver(
            forName: .shortcutDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.registerSelectedHotKey()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.saveNow()
    }

    @objc private func togglePopover() {
        if attachmentState.isDetached {
            guard let panel = floatingPanel else { return }
            panel.isVisible ? panel.orderOut(nil) : showFloatingPanel(panel)
            return
        }

        guard let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
            NotificationCenter.default.post(name: .focusScratchpad, object: nil)
        }
    }

    private func toggleAttachment() {
        attachmentState.isDetached ? attachToMenuBar() : detachToFloatingPanel()
    }

    private func detachToFloatingPanel() {
        guard let editorController else { return }
        popover.performClose(nil)
        popover.contentViewController = nil

        let panel = floatingPanel ?? makeFloatingPanel()
        panel.contentViewController = editorController
        attachmentState.isDetached = true
        showFloatingPanel(panel)
    }

    private func attachToMenuBar() {
        guard let editorController, let panel = floatingPanel else { return }
        panel.orderOut(nil)
        panel.contentViewController = nil
        popover.contentViewController = editorController
        attachmentState.isDetached = false
        togglePopover()
    }

    private func makeFloatingPanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 280),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "Papir"
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.delegate = self
        if !panel.setFrameUsingName("PapirFloatingPanel") {
            panel.center()
        }
        panel.setFrameAutosaveName("PapirFloatingPanel")
        floatingPanel = panel
        return panel
    }

    private func showFloatingPanel(_ panel: NSPanel) {
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .focusScratchpad, object: nil)
    }

    func windowWillClose(_ notification: Notification) {
        store.saveNow()
    }

    private func installHotKeyHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, context in
                guard let context else { return OSStatus(eventNotHandledErr) }
                Unmanaged<AppController>.fromOpaque(context).takeUnretainedValue().togglePopover()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &hotKeyHandler
        )
    }

    private func registerSelectedHotKey() {
        let defaults = UserDefaults.standard
        let selected = ShortcutOption(
            rawValue: defaults.string(forKey: "shortcut") ?? ShortcutOption.defaultValue.rawValue
        ) ?? .defaultValue
        guard selected != currentShortcut else { return }

        var newHotKey: EventHotKeyRef?
        let identifier = EventHotKeyID(signature: OSType(0x5041_5052), id: selected.keyCode) // PAPR
        let result = RegisterEventHotKey(
            selected.keyCode,
            UInt32(controlKey | optionKey),
            identifier,
            GetApplicationEventTarget(),
            0,
            &newHotKey
        )

        guard result == noErr else {
            defaults.set("That shortcut is already in use.", forKey: "shortcutError")
            if let currentShortcut {
                defaults.set(currentShortcut.rawValue, forKey: "shortcut")
            }
            return
        }

        if let hotKey { UnregisterEventHotKey(hotKey) }
        hotKey = newHotKey
        currentShortcut = selected
        defaults.removeObject(forKey: "shortcutError")
    }
}
