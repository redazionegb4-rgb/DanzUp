import SwiftUI

@main
struct DanzUpApp: App {
    @StateObject private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(store.appearance.colorScheme)
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                store.saveLocalData()
            }
        }
    }
}
