import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("Home", systemImage: "house.fill") }
            NavigationStack { CoursesView() }
                .tabItem { Label("Corsi", systemImage: "calendar") }
            NavigationStack { StudentsView() }
                .tabItem { Label("Allievi", systemImage: "person.3.fill") }
            NavigationStack { ManagementView() }
                .tabItem { Label("Gestione", systemImage: "square.grid.2x2.fill") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Profilo", systemImage: "person.crop.circle.fill") }
        }
        .tint(Color.dzPurple)
    }
}
