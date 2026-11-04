import SwiftUI
import UIKit

/// Cartão de uma tarefa (ícone, nome e o que já fez hoje), como na galeria.
struct ActivityCard: View {
    @Environment(Store.self) private var store
    let activity: Activity

    var body: some View {
        let info = activitySubtitle(activity, store: store)
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: activity.icon)
                .font(.system(size: 21, weight: .medium))
                .foregroundStyle(Theme.text)
                .frame(height: 24, alignment: .leading)
            Spacer(minLength: 6)
            Text(activity.cardTitle)
                .font(.inter(16, .semibold))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(info.text)
                .font(.inter(13))
                .foregroundStyle(info.done ? Theme.done : Theme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 1)
        }
        .padding(14)
        .frame(width: 148, height: 100, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Theme.track, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// O que já fez hoje (verde) ou a duração sugerida.
func activitySubtitle(_ activity: Activity, store: Store) -> (text: String, done: Bool) {
    let today = store.activitySessionsToday(activity)
    if !today.isEmpty {
        if activity.mind == .ler {
            let p = store.pagesRead(in: today)
            return (p == 1 ? "1 página hoje" : "\(p) páginas hoje", true)
        }
        let m = today.reduce(0) { $0 + $1.seconds } / 60
        if m > 0 { return ("\(m) min hoje", true) }
        return (today.count == 1 ? "Feito hoje" : "\(today.count)x hoje", true)
    }
    switch activity.mind {
    case .ler: return ("Registrar páginas", false)
    case .pensar: return ("\(activity.minutes) min, sem tela", false)
    case .escrever: return ("Algumas linhas", false)
    default: return ("\(activity.minutes) min", false)
    }
}

/// Abre a tela certa da tarefa (as de mente têm telas próprias).
struct ActivityLink<Label: View>: View {
    let activity: Activity
    @ViewBuilder let label: () -> Label

    var body: some View {
        if let mind = activity.mind {
            NavigationLink(value: mind, label: label).buttonStyle(.plain)
        } else {
            NavigationLink(value: activity, label: label).buttonStyle(.plain)
        }
    }
}

/// Lista completa de uma seção (ex.: todas as de Corpo).
struct ActivityCategoryView: View {
    @Environment(Store.self) private var store
    let category: ActivityCategory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel(text: "Em vez do celular", color: Theme.accent)
                    Text(category.title)
                        .font(.archivo(34))
                        .tracking(-0.6)
                    Text(category.subtitle)
                        .font(.inter(16))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 4)

                VStack(spacing: 10) {
                    ForEach(category.activities) { activity in
                        ActivityLink(activity: activity) {
                            row(activity)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .foregroundStyle(Theme.text)
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func row(_ activity: Activity) -> some View {
        let (subtitle, doneToday) = activitySubtitle(activity, store: store)
        return HStack(spacing: 14) {
            Image(systemName: activity.icon)
                .font(.system(size: 20, weight: .medium))
                .frame(width: 48, height: 48)
                .background(Circle().fill(Theme.track))
            VStack(alignment: .leading, spacing: 3) {
                Text(activity.title)
                    .font(.inter(16, .semibold))
                Text(activity.hint)
                    .font(.inter(13))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.inter(13, .medium))
                    .foregroundStyle(doneToday ? Theme.done : Theme.accent)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.muted)
        }
        .foregroundStyle(Theme.text)
        .card(padding: 14, radius: 20)
    }
}

/// Timer de uma tarefa do catálogo, ou só marcar "Já fiz".
struct ActivityTaskView: View {
    @Environment(Store.self) private var store
    let activity: Activity
    let onDone: () -> Void

    @State private var minutes: Int
    @State private var start: Date? = nil
    @State private var end: Date? = nil
    @State private var finishedSeconds: Int? = nil

    init(activity: Activity, onDone: @escaping () -> Void) {
        self.activity = activity
        self.onDone = onDone
        _minutes = State(initialValue: activity.minutes)
    }

    private var running: Bool { end != nil && finishedSeconds == nil }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            if let secs = finishedSeconds {
                finishedView(secs)
            } else if let end {
                runningView(end)
            } else {
                setupView
            }
            Spacer(minLength: 0)
            bottom
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .foregroundStyle(Theme.text)
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(running)
        .toolbarBackground(Theme.bg, for: .navigationBar)
    }

    private var setupView: some View {
        VStack(spacing: 20) {
            Image(systemName: activity.icon)
                .font(.system(size: 30, weight: .medium))
                .frame(width: 72, height: 72)
                .background(Circle().fill(Theme.track))
            SectionLabel(text: activity.category.title, color: Theme.accent)
            Text(activity.title)
                .font(.archivo(32))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(activity.hint)
                .font(.inter(16))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                ForEach(activity.minuteOptions, id: \.self) { m in
                    Chip(label: "\(m) min", selected: minutes == m) { minutes = m }
                }
            }
            .padding(.top, 8)
        }
    }

    private func runningView(_ end: Date) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, end.timeIntervalSince(context.date))
            VStack(spacing: 28) {
                Text(activity.title)
                    .font(.archivo(26))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                ZStack {
                    Circle().stroke(Theme.track, lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: 1 - remaining / Double(max(minutes, 1) * 60))
                        .stroke(Theme.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(clock(remaining))
                        .font(.archivo(50))
                        .monospacedDigit()
                }
                .frame(width: 220, height: 220)
                Text("Celular virado pra baixo. Quando acabar, volta aqui.")
                    .font(.inter(15))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .onChange(of: remaining <= 0) { _, over in
                if over { finish() }
            }
        }
    }

    private func finishedView(_ secs: Int) -> some View {
        VStack(spacing: 16) {
            Text("Feito.")
                .font(.archivo(44))
            Text("\(durationText(secs)) longe do scroll.")
                .font(.inter(16))
                .foregroundStyle(Theme.muted)
        }
    }

    @ViewBuilder
    private var bottom: some View {
        if let secs = finishedSeconds {
            Button("Guardar troca") { save(seconds: secs) }
                .buttonStyle(PrimaryButtonStyle())
        } else if running {
            Button("Terminei antes") { finish() }
                .font(.inter(16, .medium))
                .foregroundStyle(Theme.muted)
                .frame(height: 56)
        } else {
            VStack(spacing: 4) {
                Button("Começar") {
                    let now = Date()
                    start = now
                    end = now.addingTimeInterval(TimeInterval(minutes * 60))
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                .buttonStyle(PrimaryButtonStyle())
                Button("Já fiz") { save(seconds: 0) }
                    .font(.inter(16, .semibold))
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .contentShape(Rectangle())
            }
        }
    }

    private func finish() {
        guard finishedSeconds == nil else { return }
        let secs = Int(Date().timeIntervalSince(start ?? Date()))
        finishedSeconds = max(secs, 0)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func save(seconds: Int) {
        store.logMind(MindSession(kind: .outro, seconds: seconds, title: activity.title, activity: activity.id))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onDone()
    }

    private func clock(_ seconds: TimeInterval) -> String {
        let s = Int(seconds.rounded(.up))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    private func durationText(_ secs: Int) -> String {
        if secs < 60 { return "\(secs) segundos" }
        let m = secs / 60
        return m == 1 ? "1 minuto" : "\(m) minutos"
    }
}
