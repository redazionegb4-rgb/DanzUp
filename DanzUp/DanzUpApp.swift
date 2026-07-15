import SwiftUI
import UIKit

@main
struct DanzUpApp: App {
    @StateObject private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        configureAppearance()
    }

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

    private func configureAppearance() {
        let purple = UIColor(red: 0.43, green: 0.24, blue: 0.86, alpha: 1)
        let navigation = UINavigationBarAppearance()
        navigation.configureWithDefaultBackground()
        navigation.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        navigation.shadowColor = .clear
        navigation.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        navigation.titleTextAttributes = [.foregroundColor: UIColor.label]
        UINavigationBar.appearance().standardAppearance = navigation
        UINavigationBar.appearance().scrollEdgeAppearance = navigation
        UINavigationBar.appearance().compactAppearance = navigation
        UINavigationBar.appearance().tintColor = purple

        let tab = UITabBarAppearance()
        tab.configureWithDefaultBackground()
        tab.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        tab.shadowColor = UIColor.separator.withAlphaComponent(0.22)
        UITabBar.appearance().standardAppearance = tab
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tab
        }
        UITabBar.appearance().tintColor = purple

        UITableView.appearance().backgroundColor = .clear
        UICollectionView.appearance().backgroundColor = .clear
    }
}
