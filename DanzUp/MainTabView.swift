import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }.tabItem { Label("Home", systemImage: "sparkles") }
            NavigationStack { CoursesView() }.tabItem { Label("Corsi", systemImage: "figure.dance") }
            NavigationStack { StudentsView() }.tabItem { Label(store.userRole == .parent ? "Famiglia" : "Allievi", systemImage: "person.3.fill") }
            NavigationStack { ManagementView() }.tabItem { Label("Gestione", systemImage: "square.grid.2x2.fill") }
            NavigationStack { SettingsView() }.tabItem { Label("Profilo", systemImage: "person.crop.circle.fill") }
        }.tint(.dzPurple)
    }
}
