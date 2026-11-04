import SwiftUI
import UIKit

/// Rotina matinal: marcar cada item.
struct RoutineView: View {
    @Environment(Store.self) private var store
    @State private var editing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel(text: "Obrigatória · sua escolha de itens", color: Theme.accent)
                    Text("Rotina matinal")
                        .font(.archivo(34))
                        .tracking(-0.6)
                    Text("\(store.routineDoneCount) de \(store.data.routine.count) feitos")
                        .font(.inter(15))
                        .foregroundStyle(Theme.muted)
                }

                VStack(spacing: 8) {
                    ForEach(store.data.routine) { item in
                        let done = store.isRoutineItemDone(item)
                        Button {
                            withAnimation(.snappy) { store.toggleRoutineItem(item) }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            HStack(spacing: 14) {
                                CheckBox(done: done)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.inter(16, .medium))
                                        .foregroundStyle(done ? Theme.muted : Theme.text)
                                        .strikethrough(done, color: Theme.muted)
                                    if !item.why.isEmpty {
                                        Text(item.why)
                                            .font(.inter(13))
                                            .foregroundStyle(Theme.muted)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .card(padding: 14)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(done ? .isSelected : [])
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(coachLine)
                        .font(.archivo(17, bold: true))
                    Text(store.routineComplete
                         ? "Feita antes da tela. Isso conta como dia completo."
                         : "Quando terminar tudo, o dia de hoje conta no seu protocolo.")
                        .font(.inter(14))
                        .foregroundStyle(Theme.muted)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Theme.track, lineWidth: 1)
                )

                history
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .screenBackground()
        .foregroundStyle(Theme.text)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar rotina") { editing = true }
                    .font(.inter(15))
                    .foregroundStyle(Theme.muted)
            }
        }
        .sheet(isPresented: $editing) {
            NavigationStack { RoutineEditor() }
        }
    }

    /// Calendário da rotina: fase 1 (30 dias), depois fase 2 (até 66). 2 reservas por semana.
    private var history: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: store.phaseTarget == Store.phase1 ? "Seus dias · Fase 1 · 30 dias" : "Seus dias · Fase 2 · até 66 dias")

            let statuses = store.statuses(upTo: store.phaseTarget)
            let rowCount = (statuses.count + 5) / 6
            VStack(spacing: 8) {
                ForEach(0..<rowCount, id: \.self) { r in
                    HStack(spacing: 8) {
                        ForEach(0..<6, id: \.self) { c in
                            let index = r * 6 + c
                            if index < statuses.count {
                                RoutineDayCell(day: index + 1, status: statuses[index])
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
            .fixedSize(horizontal: false, vertical: true)

            Text("Essa sequência nunca zera. Errar um dia não apaga o que você já fez: o que conta é voltar.")
                .font(.inter(14))
                .foregroundStyle(Theme.muted)
                .lineSpacing(3)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.track, lineWidth: 1)
        )
    }

    private var coachLine: String {
        let left = store.data.routine.count - store.routineDoneCount
        if left <= 0 { return "Rotina feita. O dia é seu." }
        if left == 1 { return "Falta 1. Termina isso." }
        return "Faltam \(left). Bora terminar."
    }
}

/// Um dia no calendário da rotina (feito, reserva, perdido, hoje, futuro).
struct RoutineDayCell: View {
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
