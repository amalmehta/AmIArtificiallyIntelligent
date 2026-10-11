import SwiftUI
import AppKit
import QuizUI

@main
struct AmIArtificiallyIntelligentApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(PrefKey.appearance) private var appearance = Appearance.system.rawValue

    private var scheme: ColorScheme? { Appearance(rawValue: appearance)?.colorScheme }

    var body: some Scene {
        WindowGroup("Am I Artificially Intelligent?") {
            ContentView()
                .preferredColorScheme(scheme)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            SettingsView()
                .preferredColorScheme(scheme)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Needed when launched as a bare executable (swift run) rather than from the .app bundle.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
