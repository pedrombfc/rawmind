import SwiftUI
import Combine

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
    @Environment(Store.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            TodayView(openMonk: { tab = 1 })
                .tabItem { Label("Hoje", systemImage: "sun.max") }
                .tag(0)
            MonkModeView()
                .tabItem { Label("Monk Mode", systemImage: "flame") }
                .tag(1)
            ProgressScreen()
                .tabItem { Label("Progresso", systemImage: "chart.bar") }
                .tag(2)
            SettingsView()
                .tabItem { Label("Ajustes", systemImage: "slider.horizontal.3") }
                .tag(3)
        }
        .toolbarBackground(Theme.bg, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        // Confere o prazo da meia-noite ao abrir o app e quando o dia vira.
        .task { store.evaluateMonk() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.evaluateMonk() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            store.evaluateMonk()
        }
        .fullScreenCover(isPresented: Binding(
            get: { store.data.monk?.failure != nil },
            set: { _ in }
        )) {
            MonkFailureView()
        }
    }
}
