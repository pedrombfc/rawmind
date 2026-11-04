import SwiftUI
import UIKit

/// "Faltam 12 páginas" / "Falta 1 página".
func remainingText(_ n: Int, _ unit: String) -> String {
    if unit == "%" { return n == 1 ? "Falta 1%" : "Faltam \(n)%" }
    if n == 1 {
        let singular = unit.hasSuffix("s") ? String(unit.dropLast()) : unit
        return "Falta 1 \(singular)"
    }
    return "Faltam \(n) \(unit)"
}

/// Texto abaixo da medalha ganha: data, ou "renova toda semana".
func earnedSubtitle(_ a: Achievement, _ record: AchievementRecord?) -> String {
    switch a.period {
    case .week: return "renova toda semana"
    case .month: return "renova todo mês"
    case .forever: return record.map { PTDate.short($0.date) } ?? ""
    }
}

/// Cartão do topo do Progresso: as últimas medalhas e as que estão quase lá.
struct AchievementsCard: View {
    @Environment(Store.self) private var store

    var body: some View {
        let stats = store.achievementStats
        let recent = Array(store.recentAchievements.prefix(3))
        let near = store.nearAchievements(stats)
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink {
                AchievementsView()
            } label: {
                HStack {
                    SectionLabel(text: "Conquistas", color: Theme.accent)
                    Spacer()
                    Text("\(store.data.achievements.count) de \(Achievement.all.count)")
                        .font(.inter(14, .semibold))
                        .foregroundStyle(Theme.text)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.muted)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if recent.isEmpty {
                Text("Leia uma página, faça uma troca ou comece o Monk Mode. Sua primeira medalha aparece aqui.")
                    .font(.inter(15))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)
            } else {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(recent) { a in
                        let record = store.data.achievements[a.id]
                        VStack(spacing: 8) {
                            MedalView(achievement: a, size: 84, times: a.renews ? record?.times : nil)
                            VStack(spacing: 1) {
                                Text(a.title)
                                    .font(.inter(14, .semibold))
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(earnedSubtitle(a, record))
                                    .font(.inter(12))
                                    .foregroundStyle(Theme.muted)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    ForEach(0..<(3 - recent.count), id: \.self) { _ in
                        Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                    }
                }
                .padding(.top, 18)
            }

            if !near.isEmpty {
                Divider().overlay(Theme.track)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                SectionLabel(text: "Quase lá")
                    .padding(.bottom, 14)
                VStack(spacing: 16) {
                    ForEach(near) { a in
                        nearRow(a, stats)
                    }
                }
            }
        }
        .foregroundStyle(Theme.text)
        .card(padding: 18, radius: 20)
    }

    private func nearRow(_ a: Achievement, _ stats: AchievementStats) -> some View {
        let v = min(a.value(stats), a.goal)
        return HStack(spacing: 12) {
            MedalView(achievement: a, size: 44, locked: true)
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(a.detail.prefix(1).uppercased() + a.detail.dropFirst())
                        .font(.inter(15, .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 6)
                    Text("\(v)/\(a.goal)")
                        .font(.inter(13))
                        .foregroundStyle(Theme.muted)
                        .monospacedDigit()
                }
                ThinBar(value: a.fraction(stats), height: 6)
                    .padding(.top, 7)
                Text(remainingText(a.goal - v, a.unit))
                    .font(.inter(12))
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 5)
            }
        }
    }
}

/// Página com todas as conquistas, por grupo.
struct AchievementsView: View {
    @Environment(Store.self) private var store
    @State private var selected: Achievement? = nil

    var body: some View {
        let stats = store.achievementStats
        let earned = store.data.achievements.count
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Conquistas")
                        .font(.archivo(34))
                        .tracking(-0.6)
                    Text("\(earned) de \(Achievement.all.count) conquistadas. As de semana e de mês renovam, e você ganha de novo.")
                        .font(.inter(15))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    ThinBar(value: Double(earned) / Double(max(Achievement.all.count, 1)), height: 6, color: Theme.done)
                        .padding(.top, 6)
                }

                ForEach(Achievement.groups, id: \.self) { group in
                    let items = Achievement.all.filter { $0.group == group }
                    VStack(alignment: .leading, spacing: 14) {
                        Text(group)
                            .font(.archivo(20, bold: true))
                        VStack(spacing: 22) {
                            ForEach(Array(stride(from: 0, to: items.count, by: 3)), id: \.self) { start in
                                HStack(alignment: .top, spacing: 10) {
                                    ForEach(items[start..<min(start + 3, items.count)]) { a in
                                        cell(a, stats)
                                    }
                                    ForEach(0..<(3 - min(3, items.count - start)), id: \.self) { _ in
                                        Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .foregroundStyle(Theme.text)
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(item: $selected) { a in
            AchievementDetailSheet(achievement: a)
                .presentationDetents([.medium])
                .trackedModal()
        }
    }

    private func cell(_ a: Achievement, _ stats: AchievementStats) -> some View {
        let record = store.data.achievements[a.id]
        let locked = record == nil
        let v = min(a.value(stats), a.goal)
        return Button {
            selected = a
        } label: {
            VStack(spacing: 0) {
                MedalView(achievement: a, size: 78, locked: locked, times: a.renews ? record?.times : nil)
                Text(a.title)
                    .font(.inter(13.5, .semibold))
                    .foregroundStyle(locked ? Theme.muted : Theme.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                Text(a.detail)
                    .font(.inter(11.5))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
                if locked {
                    if a.goal > 1 {
                        ThinBar(value: a.fraction(stats), height: 5)
                            .frame(width: 78)
                            .padding(.top, 7)
                        Text("\(v)/\(a.goal)")
                            .font(.inter(11))
                            .foregroundStyle(Theme.muted)
                            .monospacedDigit()
                            .padding(.top, 4)
                    } else {
                        Text("bloqueada")
                            .font(.inter(11))
                            .foregroundStyle(Theme.muted)
                            .padding(.top, 6)
                    }
                } else {
                    Text(a.renews ? earnedSubtitle(a, record) : "conquistada")
                        .font(.inter(11, .semibold))
                        .foregroundStyle(Theme.done)
                        .padding(.top, 5)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Detalhe de uma medalha (tocar nela na página de conquistas).
struct AchievementDetailSheet: View {
    @Environment(Store.self) private var store
    let achievement: Achievement

    var body: some View {
        let stats = store.achievementStats
        let record = store.data.achievements[achievement.id]
        let v = min(achievement.value(stats), achievement.goal)
        VStack(spacing: 14) {
            MedalView(achievement: achievement, size: 120, locked: record == nil,
                      times: achievement.renews ? record?.times : nil)
                .padding(.top, 28)
            Text(achievement.title)
                .font(.archivo(28))
            Text(achievement.detail)
                .font(.inter(16))
                .foregroundStyle(Theme.muted)
            if let record {
                Text(achievement.renews && record.times > 1
                     ? "Ganha \(record.times) vezes. A última em \(PTDate.short(record.date))."
                     : "Ganha em \(PTDate.short(record.date)).")
                    .font(.inter(15, .semibold))
                    .foregroundStyle(Theme.done)
                    .multilineTextAlignment(.center)
            }
            if record == nil || (achievement.renews && v < achievement.goal) {
                if achievement.goal > 1 {
                    VStack(spacing: 6) {
                        ThinBar(value: achievement.fraction(stats), height: 6)
                        Text("\(v) de \(achievement.goal) · \(remainingText(achievement.goal - v, achievement.unit).lowercased())")
                            .font(.inter(13))
                            .foregroundStyle(Theme.muted)
                    }
                    .frame(maxWidth: 240)
                    .padding(.top, 4)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .foregroundStyle(Theme.text)
        .background(Theme.bg.ignoresSafeArea())
    }
}

/// Item para a tela de comemoração.
struct CelebrationItem: Identifiable, Hashable {
    let id: String
}

/// "Nova conquista": abre quando você ganha uma medalha.
struct AchievementUnlockedView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let id: String

    @State private var appeared = false
    @State private var shareImage: Image? = nil

    var body: some View {
        let achievement = Achievement.find(id)
        let record = store.data.achievements[id]
        ZStack {
            Theme.bg.ignoresSafeArea()
            RadialGradient(colors: [Theme.accent.opacity(0.28), Theme.bg.opacity(0)],
                           center: UnitPoint(x: 0.5, y: 0.36), startRadius: 0, endRadius: 320)
                .ignoresSafeArea()

            if let achievement {
                VStack(spacing: 0) {
                    SectionLabel(text: "Nova conquista", color: Theme.accent)
                        .padding(.top, 48)
                    MedalView(achievement: achievement, size: 180,
                              times: achievement.renews ? record?.times : nil)
                        .scaleEffect(appeared ? 1 : 0.6)
                        .opacity(appeared ? 1 : 0)
                        .padding(.top, 36)
                    Text(achievement.title)
                        .font(.archivo(38))
                        .tracking(-0.6)
                        .multilineTextAlignment(.center)
                        .padding(.top, 34)
                    Text(achievement.celebration)
                        .font(.inter(17))
                        .foregroundStyle(Color(hex: 0xC9C6BE))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 12)
                    if let next = achievement.next(earned: store.earnedAchievements) {
                        (Text("Próxima: ").foregroundColor(Theme.muted)
                         + Text(next.title).foregroundColor(Theme.text).bold()
                         + Text(" · \(next.detail.lowercased())").foregroundColor(Theme.muted))
                            .font(.inter(14))
                            .multilineTextAlignment(.center)
                            .padding(.top, 22)
                    }
                    Spacer(minLength: 16)
                    VStack(spacing: 6) {
                        if let shareImage {
                            ShareLink(item: shareImage,
                                      preview: SharePreview(achievement.title, image: shareImage)) {
                                Text("Compartilhar")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                        Button("Fechar") { dismiss() }
                            .font(.inter(16, .semibold))
                            .foregroundStyle(Theme.text)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 12)
                .foregroundStyle(Theme.text)
            } else {
                Button("Fechar") { dismiss() }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) { appeared = true }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            if let achievement { renderShareImage(achievement, times: record?.times) }
        }
    }

    @MainActor
    private func renderShareImage(_ a: Achievement, times: Int?) {
        let renderer = ImageRenderer(content: ShareStoryCard(achievement: a, times: a.renews ? times : nil))
        renderer.scale = 3
        if let ui = renderer.uiImage {
            shareImage = Image(uiImage: ui)
        }
    }
}

/// Imagem pro story (360 x 640, sai em 1080 x 1920).
struct ShareStoryCard: View {
    let achievement: Achievement
    var times: Int? = nil

    var body: some View {
        ZStack {
            Theme.bg
            RadialGradient(colors: [Theme.accent.opacity(0.3), Theme.bg.opacity(0)],
                           center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: 300)
            VStack(spacing: 0) {
                SectionLabel(text: "Nova conquista", color: Theme.accent)
                    .padding(.top, 92)
                MedalView(achievement: achievement, size: 190, times: times)
                    .padding(.top, 40)
                Text(achievement.title)
                    .font(.archivo(36))
                    .tracking(-0.6)
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                    .padding(.top, 34)
                Text(achievement.detail)
                    .font(.inter(17))
                    .foregroundStyle(Color(hex: 0xC9C6BE))
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                Spacer()
                Text("rawmind")
                    .font(.archivo(24, bold: true))
                    .foregroundStyle(Theme.text)
                Text("menos tela, mais vida")
                    .font(.inter(13))
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 2)
                    .padding(.bottom, 56)
            }
            .padding(.horizontal, 28)
        }
        .frame(width: 360, height: 640)
    }
}

/// Conta as folhas abertas, para a comemoração esperar elas fecharem.
private struct TrackedModal: ViewModifier {
    @Environment(Store.self) private var store

    func body(content: Content) -> some View {
        content
            .onAppear { store.openModals += 1 }
            .onDisappear { store.openModals = max(store.openModals - 1, 0) }
    }
}

extension View {
    /// Use no conteúdo de cada sheet / fullScreenCover.
    func trackedModal() -> some View { modifier(TrackedModal()) }
}
