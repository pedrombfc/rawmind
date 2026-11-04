import SwiftUI
import UIKit

/// Tela "Hoje": rotina matinal (sempre), hábitos do Monk Mode (se ativo) e botão de foco.
struct TodayView: View {
    @Environment(Store.self) private var store
    var openMonk: () -> Void = {}
    @State private var showFocus = false
    @State private var showSwap = false
    @State private var screenForm: ScreenTimeCard.ScreenFormMode? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    if store.monkActive {
                        ThinBar(value: Double(min(store.monkDay, Store.monkDays)) / Double(Store.monkDays))
                    }
                    routineCard
                    swapCard
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
        .fullScreenCover(isPresented: $showSwap) {
            SwapSheet()
        }
        .sheet(item: $screenForm) { mode in
            NavigationStack { ScreenTimeForm(isBaseline: mode == .baseline) }
        }
    }

    // MARK: Partes

    /// Topo: data e quanto tempo de celular por dia você cortou desde antes do Rawmind.
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(PTDate.long(Date()))
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
                Spacer(minLength: 8)
                if store.needsScreenUpdate {
                    Button { screenForm = .week } label: {
                        Text("Anotar esta semana →")
                            .font(.inter(14, .semibold))
                            .foregroundStyle(Theme.accent)
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let base = store.data.screenBaseline {
                if let now = store.latestScreen {
                    let saved = base.totalMinutes - now.totalMinutes
                    VStack(alignment: .leading, spacing: 2) {
                        bigNumber(saved > 0 ? "−\(Store.durationText(saved))" : (saved < 0 ? "+\(Store.durationText(-saved))" : "0 min"),
                                  color: saved > 0 ? Theme.done : (saved < 0 ? Theme.accent : Theme.text))
                        Text(saved > 0
                             ? "de celular, comparado com antes do Rawmind"
                             : (saved < 0
                                ? "a mais que antes. Semana difícil acontece: o que conta é a tendência."
                                : "de diferença por enquanto. Normal no começo."))
                            .font(.inter(14))
                            .foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    HStack(spacing: 8) {
                        compareTile("Celular", before: base.totalMinutes, now: now.totalMinutes)
                        compareTile("Instagram", before: base.instagramMinutes, now: now.instagramMinutes)
                        if saved > 0 {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Por semana")
                                    .font(.inter(12))
                                    .foregroundStyle(Theme.muted)
                                Text("+\(Store.durationText(saved * 7))")
                                    .font(.inter(15, .semibold))
                                    .foregroundStyle(Theme.done)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        bigNumber(Store.durationText(base.totalMinutes), color: Theme.text)
                        let wait = store.daysUntilScreenUpdate
                        Text(wait == 0
                             ? "é o seu ponto de partida. Anote esta semana pra ver quanto ganhou."
                             : "é o seu ponto de partida. \(wait == 1 ? "Amanhã" : "Daqui a \(wait) dias") você anota de novo e vê quanto ganhou.")
                            .font(.inter(14))
                            .foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quanto do seu dia vai pro celular?")
                        .font(.archivo(28))
                        .tracking(-0.5)
                        .fixedSize(horizontal: false, vertical: true)
                    Button { screenForm = .baseline } label: {
                        Text("Anotar agora →")
                            .font(.inter(15, .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func bigNumber(_ value: String, color: Color) -> some View {
        (Text(value).foregroundColor(color)
         + Text(" por dia").font(.archivo(20)).foregroundColor(Theme.muted))
            .font(.archivo(44))
            .tracking(-0.8)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private func compareTile(_ title: String, before: Int, now: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.inter(12))
                .foregroundStyle(Theme.muted)
            HStack(spacing: 4) {
                Text(Store.durationText(before))
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
                    .strikethrough(true, color: Theme.muted)
                Text(Store.durationText(now))
                    .font(.inter(14, .semibold))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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

    private var swapCard: some View {
        Button {
            showSwap = true
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vontade de pegar o celular?")
                        .font(.archivo(19, bold: true))
                        .foregroundStyle(Theme.text)
                    Text("Troca por 3 minutos de pensar, escrever ou ler.")
                        .font(.inter(14))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.bg)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.accent))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: 0x1F1A12))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Theme.accent, lineWidth: 1.5)
            )
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
        if store.monkActive {
            VStack(alignment: .leading, spacing: 8) {
                let missing = store.monkHabits.count - store.monkDoneToday
                SectionLabel(text: missing == 0 ? "Monk Mode · tudo feito hoje" : "Monk Mode · faltam \(missing) até meia-noite",
                             color: missing == 0 ? Theme.done : Theme.muted)
                ForEach(store.monkHabits) { habit in
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
                            Text(habit.sideText)
                                .font(.inter(13))
                                .foregroundStyle(Theme.muted)
                        }
                        .card(padding: 14)
                    }
                    .buttonStyle(.plain)
                }
            }
        } else if !store.monkCompleted {
            Button(action: openMonk) {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monk Mode parado")
                            .font(.archivo(19, bold: true))
                            .foregroundStyle(Theme.text)
                        Text("\(Store.monkDays) dias, \(Store.minHabits) hábitos ou mais, sem desculpa.")
                            .font(.inter(14))
                            .foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                    Text("Iniciar")
                        .font(.inter(15, .semibold))
                        .foregroundStyle(Theme.accent)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.accent)
                }
                .card(padding: 18, radius: 20)
            }
            .buttonStyle(.plain)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statTile(value: "\(store.completedDays)", label: store.completedDays == 1 ? "dia com a rotina feita" : "dias com a rotina feita")
            statTile(value: "\(store.swapsToday)", label: store.swapsToday == 1 ? "troca hoje" : "trocas hoje")
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
