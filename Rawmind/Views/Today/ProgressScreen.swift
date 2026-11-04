import SwiftUI

/// Progresso: tempo de tela antes x agora, trocas da semana, caderno, Monk Mode e rotina.
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

                    ScreenTimeCard()

                    mindCard

                    let week = store.mindLastWeek
                    HStack(spacing: 10) {
                        tile("\(store.mindMinutes(.pensar, in: week))", "min pensando")
                        tile("\(store.mindMinutes(.ler, in: week))", "min lendo")
                        tile("\(week.reduce(0) { $0 + $1.wordCount })", "palavras escritas")
                    }

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

                    monkCard
                        .padding(.top, 8)

                    routineSection
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .foregroundStyle(Theme.text)
            .screenBackground()
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

    // MARK: Monk Mode

    private var monkCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Monk Mode", color: Theme.accent)
            HStack(spacing: 10) {
                if store.monkActive {
                    tile("Dia \(min(store.monkDay, Store.monkDays))", "de \(Store.monkDays)")
                } else if store.monkCompleted {
                    tile("\(Store.monkDays) ✓", "completo")
                } else {
                    tile("Parado", "na aba Monk Mode")
                }
                tile("\(store.monkRecord)", store.monkRecord == 1 ? "dia de recorde" : "dias de recorde")
                tile("\(store.monkAttempts)", store.monkAttempts == 1 ? "tentativa" : "tentativas")
            }
        }
    }

    // MARK: Rotina matinal

    private var routineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: store.phaseTarget == Store.phase1 ? "Rotina matinal · Fase 1 · 30 dias" : "Rotina matinal · Fase 2 · até 66 dias")

            let statuses = store.statuses(upTo: store.phaseTarget)
            let rowCount = (statuses.count + 5) / 6
            VStack(spacing: 8) {
                ForEach(0..<rowCount, id: \.self) { r in
                    HStack(spacing: 8) {
                        ForEach(0..<6, id: \.self) { c in
                            let index = r * 6 + c
                            if index < statuses.count {
                                DayCell(day: index + 1, status: statuses[index])
                            } else {
                                Color.clear.frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }

            HStack(spacing: 16) {
                legendItem(Theme.done, "Feito")
                legendItem(Theme.accent.opacity(0.35), "Reserva")
                legendItem(Theme.track, "Perdido")
            }
            .font(.inter(13))
            .foregroundStyle(Theme.muted)

            HStack(spacing: 10) {
                tile("\(store.completedDays)", "dias com a rotina feita")
                tile("\(store.reservesLeftThisWeek)", "reservas nesta semana")
                tile("\(store.totalFocusMinutes)", "min de foco")
            }

            Text("A sequência nunca zera. Errar um dia não apaga o que você já fez: o que conta é voltar.")
                .font(.inter(15))
                .foregroundStyle(Theme.muted)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func legendItem(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 12, height: 12)
            Text(label)
        }
    }

    private func tile(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.archivo(22, bold: true))
            Text(label)
                .font(.inter(12))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.track, lineWidth: 1)
        )
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

private struct DayCell: View {
    let day: Int
    let status: DayStatus

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(fill)
            if status == .today {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Theme.accent, lineWidth: 2)
            }
            Text("\(day)")
                .font(.inter(14, status == .done ? .semibold : .regular))
                .foregroundStyle(textColor)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Dia \(day), \(label)")
    }

    private var fill: Color {
        switch status {
        case .done: return Theme.done
        case .reserve: return Theme.accent.opacity(0.35)
        case .missed: return Theme.track
        case .today: return Theme.card
        case .future: return Theme.card.opacity(0.6)
        }
    }

    private var textColor: Color {
        switch status {
        case .done: return Theme.bg
        case .future: return Theme.muted.opacity(0.6)
        default: return Theme.text
        }
    }

    private var label: String {
        switch status {
        case .done: return "feito"
        case .reserve: return "dia de reserva"
        case .missed: return "perdido"
        case .today: return "hoje"
        case .future: return "ainda não chegou"
        }
    }
}
