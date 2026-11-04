import SwiftUI

/// Progresso: os 30 dias da fase 1 (depois 66), com dias feitos e reservas.
struct ProgressScreen: View {
    @Environment(Store.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel(text: store.phaseTarget == Store.phase1 ? "Fase 1 · 30 dias" : "Fase 2 · até 66 dias", color: Theme.accent)
                        Text("Progresso")
                            .font(.archivo(34))
                            .tracking(-0.6)
                    }

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

                    legend

                    HStack(spacing: 10) {
                        tile("\(store.completedDays)", "dias completos")
                        tile("\(store.reservesLeftThisWeek)", "reservas nesta semana")
                        tile("\(store.totalFocusMinutes)", "min de foco")
                    }

                    Text("A sequência nunca zera. Errar um dia não apaga o que você já fez: o que conta é voltar.")
                        .font(.inter(15))
                        .foregroundStyle(Theme.muted)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
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

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(Theme.done, "Feito")
            legendItem(Theme.accent.opacity(0.35), "Reserva")
            legendItem(Theme.track, "Perdido")
        }
        .font(.inter(13))
        .foregroundStyle(Theme.muted)
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
