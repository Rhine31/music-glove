import SwiftUI

@main
struct MusicGloveApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .tint(MGTheme.accent)
        }
    }
}
