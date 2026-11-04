import SwiftUI

/// Progresso: conquistas, tempo de tela antes x agora, trocas da semana e caderno.
struct ProgressScreen: View {
    @Environment(Store.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Progresso")
                        .font(.archivo(34))
                        .tracking(-0.6)
                        .padding(.bottom, 4)

                    AchievementsCard()

                    ScreenTimeCard()

                    mindCard

                    NavigationLink {
                        JournalView()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "pencil.line")
                                .font(.system(size: 20, weight: .medium))
                                .frame(width: 48, height: 48)
                                .background(Circle().fill(Theme.track))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Seu caderno").font(.inter(16, .semibold))
                                Text(store.journal.count == 1 ? "1 texto" : "\(store.journal.count) textos")
                                    .font(.inter(14))
                                    .foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
                        }
                        .foregroundStyle(Theme.text)
                        .card(padding: 14, radius: 20)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .foregroundStyle(Theme.text)
            .screenBackground()
            .statusBarCover()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: Sua mente

    private var mindCard: some View {
        let counts = store.mindDailyCounts
        let total = counts.reduce(0) { $0 + $1.count }
        return VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Sua mente · últimos 7 dias", color: Theme.accent)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(total)").font(.archivo(44))
                Text(total == 1 ? "troca em vez do celular" : "trocas em vez do celular")
                    .font(.inter(15))
                    .foregroundStyle(Theme.muted)
            }
            WeekBars(counts: counts)
        }
        .card(padding: 18, radius: 20)
    }
}

/// Barras das trocas de cada dia (hoje em âmbar).
private struct WeekBars: View {
    let counts: [DayCount]

    var body: some View {
        let maxValue = max(counts.map(\.count).max() ?? 0, 1)
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(counts.enumerated()), id: \.offset) { index, day in
                let isToday = index == counts.count - 1
                VStack(spacing: 6) {
                    Text("\(day.count)")
                        .font(.inter(12))
                        .foregroundStyle(Theme.muted)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isToday ? Theme.accent : (day.count == 0 ? Theme.track : Theme.done))
                        .frame(height: CGFloat(day.count) / CGFloat(maxValue) * 90 + 4)
                    Text(isToday ? "HOJE" : weekday(day.date))
                        .font(.inter(11, .semibold))
                        .foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 140, alignment: .bottom)
    }

    private func weekday(_ date: Date) -> String {
        let names = ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SÁB"]
        return names[(Calendar.current.component(.weekday, from: date) - 1) % 7]
    }
}

