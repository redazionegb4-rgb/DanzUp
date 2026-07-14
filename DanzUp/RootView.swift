import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: AppStore
    var body: some View { Group { if store.isAuthenticated { MainTabView() } else { WelcomeView() } }.animation(.easeInOut(duration: 0.25), value: store.isAuthenticated) }
}
