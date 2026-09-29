import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @AppStorage("fontName") private var fontName = "System"
    @AppStorage("fontSize") private var fontSize = 14.0
    @AppStorage("shortcut") private var shortcut = ShortcutOption.defaultValue.rawValue
    @AppStorage("shortcutError") private var shortcutError = ""
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @State private var launchError = ""

    var body: some View {
        Form {
            Section("Editor") {
                Picker("Font", selection: $fontName) {
                    Text("System").tag("System")
                    ForEach(NSFontManager.shared.availableFontFamilies, id: \.self) { font in
                        Text(font).tag(font)
                    }
                }

                Stepper("Font size: \(fontSize.formatted()) pt", value: $fontSize, in: 10...32)
            }

            Section("General") {
                Picker("Keyboard shortcut", selection: $shortcut) {
                    ForEach(ShortcutOption.allCases) { option in
                        Text(option.label).tag(option.rawValue)
                    }
                }
                .onChange(of: shortcut) {
                    NotificationCenter.default.post(name: .shortcutDidChange, object: nil)
                }

                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLogin },
                    set: updateLaunchAtLogin
                ))

                LabeledContent("Storage", value: "Local only")
            }

            if !shortcutError.isEmpty || !launchError.isEmpty {
                Section {
                    Text(shortcutError.isEmpty ? launchError : shortcutError)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 330)
        .padding()
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = enabled
            launchError = ""
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            launchError = "Papir could not update the login item: \(error.localizedDescription)"
        }
    }
}
