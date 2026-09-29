import SwiftUI

@MainActor
final class AttachmentState: ObservableObject {
    @Published var isDetached = false
}

struct ScratchpadView: View {
    @ObservedObject var store: ScratchpadStore
    @ObservedObject var attachmentState: AttachmentState
    let toggleAttachment: () -> Void
    @AppStorage("fontName") private var fontName = "System"
    @AppStorage("fontSize") private var fontSize = 14.0
    @FocusState private var editorIsFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: Binding(
                get: { store.text },
                set: { store.updateText($0) }
            ))
                .font(editorFont)
                .focused($editorIsFocused)
                .scrollContentBackground(.hidden)
                .padding(8)
                .accessibilityLabel("Scratchpad")

            Divider()

            HStack {
                Text(store.limitMessage ?? "\(store.text.count.formatted()) / \(ScratchpadStore.characterLimit.formatted())")
                    .foregroundStyle(store.limitMessage == nil ? Color.secondary : Color.red)
                    .accessibilityLabel("\(store.text.count) of \(ScratchpadStore.characterLimit) characters")

                Spacer()

                Button(action: toggleAttachment) {
                    Image(systemName: attachmentState.isDetached ? "menubar.rectangle" : "macwindow.on.rectangle")
                }
                .buttonStyle(.borderless)
                .help(attachmentState.isDetached ? "Return to Menu Bar" : "Detach")

                SettingsLink {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help("Settings")

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.borderless)
                .help("Quit Papir")
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .frame(height: 32)

            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                    .accessibilityLabel("Storage error: \(errorMessage)")
            }
        }
        .frame(width: 360, height: 280)
        .onAppear {
            editorIsFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusScratchpad)) { _ in
            editorIsFocused = true
        }
        .onDisappear {
            store.saveNow()
        }
    }

    private var editorFont: Font {
        fontName == "System" ? .system(size: fontSize) : .custom(fontName, size: fontSize)
    }
}
