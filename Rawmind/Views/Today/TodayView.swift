import SwiftUI
import UIKit

/// Tela "Hoje": dia do protocolo, rotina matinal, hábitos e botão de foco.
struct TodayView: View {
    @Environment(Store.self) private var store
    @State private var showFocus = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    ThinBar(value: Double(min(store.dayNumber, store.phaseTarget)) / Double(store.phaseTarget))
                    routineCard
                    habitsSection
                    statsRow
                    focusButton
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .screenBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { value in
                if value == "routine" { RoutineView() }
            }
        }
        .sheet(isPresented: $showFocus) {
            FocusView()
        }
    }

    // MARK: Partes

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(PTDate.long(Date()))
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
                (Text("Dia \(store.dayNumber)").foregroundColor(Theme.text)
                 + Text(" de \(store.phaseTarget)").font(.archivo(20)).foregroundColor(Theme.muted))
                    .font(.archivo(40))
                    .tracking(-0.8)
            }
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(Theme.muted).frame(width: 8, height: 8)
                Text("Escudo em breve")
                    .font(.inter(13, .medium))
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Theme.card))
        }
    }

    private var routineCard: some View {
        NavigationLink(value: "routine") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Rotina matinal")
                        .font(.archivo(19, bold: true))
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Text("\(store.routineDoneCount) de \(store.data.routine.count)")
                        .font(.inter(14, .semibold))
                        .foregroundStyle(store.routineComplete ? Theme.done : Theme.accent)
                }
                HStack(spacing: 6) {
                    ForEach(store.data.routine) { item in
                        Capsule()
                            .fill(store.isRoutineItemDone(item) ? Theme.done : Theme.track)
                            .frame(height: 6)
                    }
                }
                Text(routineSubtitle)
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.leading)
            }
            .card(padding: 18, radius: 20)
        }
        .buttonStyle(.plain)
    }

    private var routineSubtitle: String {
        if store.routineComplete { return "Feita. O dia é seu." }
        let missing = store.data.routine.filter { !store.isRoutineItemDone($0) }.map(\.title)
        if missing.count > 2 { return "Começa às \(store.routineTimeText). Toque para abrir." }
        return "Falta: " + missing.joined(separator: ", ")
    }

    @ViewBuilder
    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Seus hábitos de hoje")
            if store.data.habits.isEmpty {
                Text("Nenhum hábito ainda. Crie os seus na aba Monk Mode.")
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
                    .padding(.vertical, 4)
            } else {
                ForEach(store.data.habits) { habit in
                    let done = store.isHabitDone(habit)
                    Button {
                        withAnimation(.snappy) { store.toggleHabit(habit) }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack(spacing: 12) {
                            CheckBox(done: done, size: 24)
                            Text(habit.title)
                                .font(.inter(15))
                                .foregroundStyle(done ? Theme.muted : Theme.text)
                                .strikethrough(done, color: Theme.muted)
                            Spacer(minLength: 0)
                            Text(habit.avoid ? "Evitar" : habit.period.rawValue)
                                .font(.inter(13))
                                .foregroundStyle(Theme.muted)
                        }
                        .card(padding: 14)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statTile(value: "\(store.completedDays)", label: store.completedDays == 1 ? "dia com a rotina feita" : "dias com a rotina feita")
            statTile(value: "\(store.reservesLeftThisWeek)", label: store.reservesLeftThisWeek == 1 ? "reserva nesta semana" : "reservas nesta semana")
        }
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.archivo(22, bold: true))
            Text(label)
                .font(.inter(13))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.track, lineWidth: 1)
        )
    }

    private var focusButton: some View {
        Button {
            showFocus = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "lock")
                    .font(.system(size: 18, weight: .bold))
                Text("Lock in · sessão de foco")
            }
            .font(.archivo(20))
            .foregroundStyle(Theme.bg)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Datas em português, no formato do design ("Quarta, 5 de novembro").
enum PTDate {
    static let weekdays = ["Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"]
    static let months = ["janeiro", "fevereiro", "março", "abril", "maio", "junho",
                         "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"]

    static func long(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.weekday, .day, .month], from: date)
        let w = weekdays[((c.weekday ?? 1) - 1) % 7]
        let m = months[((c.month ?? 1) - 1) % 12]
        return "\(w), \(c.day ?? 1) de \(m)"
    }

    static func short(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.day, .month], from: date)
        let m = months[((c.month ?? 1) - 1) % 12]
        return "\(c.day ?? 1) de \(m)"
    }
}
