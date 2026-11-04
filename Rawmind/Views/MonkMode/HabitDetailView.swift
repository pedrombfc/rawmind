import SwiftUI
import UIKit

/// Página de um hábito: progresso, calendário, nota do dia e conclusão.
struct HabitDetailView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let habitID: UUID

    @State private var noteDraft = ""
    @State private var editing = false
    @State private var concluding = false
    @State private var confirmDelete = false
    @FocusState private var noteFocused: Bool

    private var habit: Habit? { store.data.habits.first { $0.id == habitID } }

    var body: some View {
        Group {
            if let habit {
                content(habit)
            } else {
                Color.clear
            }
        }
        .screenBackground()
        .foregroundStyle(Theme.text)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Editar", systemImage: "pencil") { editing = true }
                    Button("Apagar hábito", systemImage: "trash", role: .destructive) { confirmDelete = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $editing) {
            if let habit { NavigationStack { HabitFormView(existing: habit) } }
        }
        .sheet(isPresented: $concluding) {
            if let habit { NavigationStack { ConclusionView(habit: habit) } }
        }
        .confirmationDialog("Apagar este hábito?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Apagar", role: .destructive) {
                if let habit { store.deleteHabit(habit) }
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("O histórico dele também some.")
        }
        .onAppear {
            if let habit { noteDraft = store.note(for: habit) }
        }
        .onDisappear {
            if let habit, noteDraft != store.note(for: habit) { store.setNote(noteDraft, for: habit) }
        }
    }

    @ViewBuilder
    private func content(_ habit: Habit) -> some View {
        let done = store.habitDoneDays(habit)
        let doneToday = store.isHabitDone(habit)
        ScrollView {
            VStack(spacing: 16) {
                // Topo
                VStack(spacing: 10) {
                    ProgressRing(value: Double(done) / Double(habit.target), color: doneToday ? Theme.done : Theme.accent, size: 120, lineWidth: 8) {
                        Image(systemName: doneToday ? "checkmark" : (habit.avoid ? "nosign" : "flame"))
                            .font(.system(size: 40, weight: .semibold))
                    }
                    Text(habit.title)
                        .font(.archivo(28))
                        .multilineTextAlignment(.center)
                    Text("Dia \(min(store.dayNumber, store.phaseTarget)) de \(Store.phase1) · \(habit.frequencyText)")
                        .font(.inter(15))
                        .foregroundStyle(Theme.muted)
                }
                .padding(.top, 16)

                if !habit.why.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel(text: "O que você espera que mude")
                        Text(habit.why).font(.inter(16))
                    }
                    .card(padding: 18, radius: 20)
                }

                // Progresso: um número claro
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(habit.avoid ? "\(done) \(done == 1 ? "dia limpo" : "dias limpo")" : "\(done) de \(habit.target) vezes")
                            .font(.archivo(22, bold: true))
                        Spacer()
                        Text("\(Int((Double(done) / Double(habit.target) * 100).rounded()))%")
                            .font(.inter(15, .semibold))
                            .foregroundStyle(Theme.muted)
                    }
                    ThinBar(value: Double(done) / Double(habit.target), height: 8, color: Theme.done)
                    if !habit.avoid && habit.perWeek < 7 {
                        Text("Esta semana: \(store.habitDoneThisWeek(habit)) de \(habit.perWeek)")
                            .font(.inter(14))
                            .foregroundStyle(Theme.muted)
                    }
                }
                .card(padding: 18, radius: 20)

                MonthCalendar(habit: habit)
                    .card(padding: 18, radius: 20)

                // Nota do dia
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(text: "Como foi hoje")
                    TextField("", text: $noteDraft, prompt: Text(habit.avoid ? "Ex.: deu vontade às 22h, segurei" : "Ex.: li 15 páginas do livro X").foregroundStyle(Theme.muted), axis: .vertical)
                        .font(.inter(16))
                        .lineLimit(2...5)
                        .focused($noteFocused)
                        .onChange(of: noteFocused) { _, focused in
                            if !focused { store.setNote(noteDraft, for: habit) }
                        }
                        .submitLabel(.done)
                    let past = store.notes(for: habit).filter { $0.key != store.todayKey }
                    if !past.isEmpty {
                        Divider().overlay(Theme.track)
                        ForEach(Array(past.prefix(10))) { entry in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(label(forKey: entry.key))
                                    .font(.inter(12, .semibold))
                                    .foregroundStyle(Theme.muted)
                                Text(entry.text).font(.inter(15))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .card(padding: 18, radius: 20)

                conclusionCard(habit)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            Button {
                store.toggleHabit(habit)
                UINotificationFeedbackGenerator().notificationOccurred(doneToday ? .warning : .success)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: doneToday ? "checkmark.circle.fill" : "checkmark")
                    Text(doneToday ? (habit.avoid ? "Hoje eu me mantive ✓" : "Feito hoje ✓") : (habit.avoid ? "Hoje eu me mantive" : "Feito hoje"))
                }
                .font(.archivo(19, bold: true))
                .foregroundStyle(doneToday ? Theme.done : Theme.bg)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(doneToday ? Theme.doneBg : Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(Theme.bg)
        }
    }

    @ViewBuilder
    private func conclusionCard(_ habit: Habit) -> some View {
        if let c = store.conclusion(for: habit) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: "Sua conclusão · \(c.decision.rawValue)", color: Theme.accent)
                Text(c.text.isEmpty ? "Sem texto." : c.text).font(.inter(15))
                Button("Editar conclusão") { concluding = true }
                    .font(.inter(15, .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .card(padding: 18, radius: 20)
        } else {
            let ready = store.dayNumber >= Store.phase1
            Button {
                concluding = true
            } label: {
                VStack(spacing: 4) {
                    Label("Escrever conclusão", systemImage: "square.and.pencil")
                        .font(.archivo(17, bold: true))
                    Text(ready ? "Os 30 dias acabaram. O que mudou?" : "Liberada no dia 30 (faltam \(Store.phase1 - store.dayNumber))")
                        .font(.inter(13))
                        .foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!ready)
            .opacity(ready ? 1 : 0.6)
        }
    }

    private func label(forKey key: String) -> String {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              let date = Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
        else { return key }
        return PTDate.short(date)
    }
}

/// Calendário do mês. Dias fora dos 30 dias não contam (nada de X).
struct MonthCalendar: View {
    @Environment(Store.self) private var store
    let habit: Habit
    @State private var monthOffset = 0

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        let month = calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
        let days = gridDays(for: month)
        VStack(spacing: 14) {
            HStack {
                Button { monthOffset -= 1 } label: { Image(systemName: "chevron.left").frame(width: 44, height: 32) }
                    .accessibilityLabel("Mês anterior")
                Spacer()
                Text(title(for: month)).font(.archivo(17, bold: true))
                Spacer()
                Button { monthOffset += 1 } label: { Image(systemName: "chevron.right").frame(width: 44, height: 32) }
                    .disabled(monthOffset >= 0)
                    .accessibilityLabel("Próximo mês")
            }
            .foregroundStyle(Theme.text)

            let symbols = weekdaySymbols()
            let rows = stride(from: 0, to: days.count, by: 7).map { start in
                (0..<7).map { i in start + i < days.count ? days[start + i] : nil }
            }
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { i in
                        Text(symbols[i])
                            .font(.inter(11, .semibold))
                            .foregroundStyle(Theme.muted)
                            .frame(maxWidth: .infinity)
                    }
                }
                ForEach(0..<rows.count, id: \.self) { r in
                    HStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { c in
                            if let date = rows[r][c] {
                                DayDot(date: date, state: state(for: date))
                            } else {
                                Color.clear.frame(maxWidth: .infinity).frame(height: 36)
                            }
                        }
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 14) {
                legend(Theme.done, "Feito")
                legend(Theme.track, "Não marcado")
                legend(Theme.accent, "Hoje", ring: true)
            }
            .font(.inter(12))
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    enum DotState { case done, open, today, outside, future }

    private func state(for date: Date) -> DotState {
        let day = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        let start = store.data.startDate.map { calendar.startOfDay(for: $0) } ?? today
        let end = calendar.date(byAdding: .day, value: Store.phase2 - 1, to: start) ?? today
        if store.isHabitDone(habit, on: day) { return .done }
        if day == today { return .today }
        if day < start || day > end { return .outside }
        if day > today { return .future }
        return .open
    }

    private func gridDays(for month: Date) -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let first = interval.start
        let weekday = calendar.component(.weekday, from: first)
        let lead = (weekday - calendar.firstWeekday + 7) % 7
        let count = calendar.range(of: .day, in: .month, for: month)?.count ?? 30
        var result: [Date?] = Array(repeating: nil, count: lead)
        for i in 0..<count {
            result.append(calendar.date(byAdding: .day, value: i, to: first))
        }
        return result
    }

    private func title(for month: Date) -> String {
        let c = calendar.dateComponents([.month, .year], from: month)
        let name = PTDate.months[((c.month ?? 1) - 1) % 12]
        return name.prefix(1).uppercased() + name.dropFirst() + " \(c.year ?? 0)"
    }

    private func weekdaySymbols() -> [String] {
        let base = ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SÁB"]
        let shift = calendar.firstWeekday - 1
        return (0..<7).map { base[($0 + shift) % 7] }
    }

    private func legend(_ color: Color, _ label: String, ring: Bool = false) -> some View {
        HStack(spacing: 6) {
            if ring {
                Circle().strokeBorder(color, lineWidth: 2).frame(width: 12, height: 12)
            } else {
                Circle().fill(color).frame(width: 12, height: 12)
            }
            Text(label)
        }
    }
}

private struct DayDot: View {
    let date: Date
    let state: MonthCalendar.DotState

    var body: some View {
        let day = Calendar.current.component(.day, from: date)
        ZStack {
            switch state {
            case .done:
                Circle().fill(Theme.done)
            case .open:
                Circle().fill(Theme.track)
            case .today:
                Circle().strokeBorder(Theme.accent, lineWidth: 2)
            case .future:
                Circle().strokeBorder(Theme.track, lineWidth: 1)
            case .outside:
                Color.clear
            }
            Text("\(day)")
                .font(.inter(14, state == .done ? .semibold : .regular))
                .foregroundStyle(state == .done ? Theme.bg : (state == .outside ? Theme.muted.opacity(0.4) : Theme.text))
        }
        .frame(height: 36)
        .frame(maxWidth: .infinity)
    }
}
