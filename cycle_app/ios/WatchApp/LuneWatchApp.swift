import SwiftUI

@main
struct LuneWatchApp: App {
    @StateObject private var sessionManager = WatchSessionManager()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                CycleRingView()
            }
            .environmentObject(sessionManager)
        }
    }
}
