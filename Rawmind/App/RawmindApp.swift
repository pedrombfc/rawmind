import SwiftUI

@main
struct RawmindApp: App {
    @State private var store = Store()

    init() {
        Theme.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}

/// Decide qual tela mostrar: o onboarding (primeira vez) ou o app em si.
struct RootView: View {
    @Environment(Store.self) private var store

    var body: some View {
        Group {
            if store.data.onboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Hoje", systemImage: "sun.max") }
            MonkModeView()
                .tabItem { Label("Monk Mode", systemImage: "flame") }
            ProgressScreen()
                .tabItem { Label("Progresso", systemImage: "chart.bar") }
            SettingsView()
                .tabItem { Label("Ajustes", systemImage: "slider.horizontal.3") }
        }
        .toolbarBackground(Theme.bg, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
