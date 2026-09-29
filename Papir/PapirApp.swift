import SwiftUI

@main
struct PapirApp: App {
    @NSApplicationDelegateAdaptor(AppController.self) private var appController

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
