import SwiftUI
import UIKit

/// Iniciar o Monk Mode: escolher 5 hábitos ou mais, depois segurar "lock in".
struct MonkStartFlow: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var options: [Habit] = []
    @State private var selected: [UUID] = []
    @State private var showNew = false
    @State private var loaded = false

    private var chosen: [Habit] {
        selected.compactMap { id in options.first { $0.id == id } }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 8)

            ScrollView {
                Group {
                    if step == 0 { habitsStep } else { commitStep }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .id(step)
                .transition(.opacity)
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(Theme.bg)
            }
        }
        .foregroundStyle(Theme.text)
        .screenBackground()
        .statusBarCover()
        .animation(.easeInOut(duration: 0.25), value: step)
        .sheet(isPresented: $showNew) {
            NavigationStack {
                HabitFormView(existing: nil, onCreate: { habit in
                    options.append(habit)
                    if selected.count < Store.maxHabits { selected.append(habit.id) }
                })
            }
        }
        .onAppear(perform: load)
    }

    // MARK: Topo e rodapé

    private var topBar: some View {
        ZStack {
            HStack {
                if step == 0 {
                    Button("Cancelar") { dismiss() }
                        .font(.inter(17))
                        .foregroundStyle(Theme.accent)
                } else {
                    Button {
                        step = 0
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(width: 44, height: 44, alignment: .leading)
                    }
                    .foregroundStyle(Theme.text)
                    .accessibilityLabel("Voltar")
                }
                Spacer()
            }
            Text("\(step + 1) de 2")
                .font(.inter(16, .semibold))
        }
        .frame(height: 44)
    }

    @ViewBuilder
    private var bottomBar: some View {
        if step == 0 {
            let n = selected.count
            Button {
                step = 1
            } label: {
                Text(n >= Store.minHabits
                     ? "Continuar · \(n) escolhidos"
                     : "Escolha mais \(Store.minHabits - n)")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(n < Store.minHabits)
        } else {
            VStack(spacing: 14) {
                HoldToCommitButton { begin() }
                Text("Segure por 3 segundos para começar")
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
            }
        }
    }

    // MARK: 1. Hábitos

    private var habitsStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quais hábitos entram?")
                .font(.archivo(30))
                .tracking(-0.5)
            Text("No mínimo \(Store.minHabits). Escolha coisas que você consegue fazer todo santo dia.")
                .font(.inter(15))
                .foregroundStyle(Theme.muted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 6)

            ForEach(options) { habit in
                let on = selected.contains(habit.id)
                let full = selected.count >= Store.maxHabits
                Button {
                    toggle(habit)
                } label: {
                    HStack(spacing: 12) {
                        CheckBox(done: on, size: 26, color: Theme.accent)
                        Text(habit.title)
                            .font(.inter(16, .medium))
                            .foregroundStyle(Theme.text)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        Text(habit.avoid ? "Evitar" : "")
                            .font(.inter(13))
                            .foregroundStyle(Theme.muted)
                    }
                    .card(padding: 14)
                    .opacity(on || !full ? 1 : 0.45)
                }
                .buttonStyle(.plain)
            }

            Button {
                showNew = true
            } label: {
                Label("Criar um hábito meu", systemImage: "plus")
                    .font(.inter(15, .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

            Text("Até \(Store.maxHabits) hábitos.")
                .font(.inter(13))
                .foregroundStyle(Theme.muted)
                .padding(.top, 2)
        }
    }

    private func toggle(_ habit: Habit) {
        if let i = selected.firstIndex(of: habit.id) {
            selected.remove(at: i)
        } else if selected.count < Store.maxHabits {
            selected.append(habit.id)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: 2. Compromisso

    private var commitStep: some View {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: Store.monkDays - 1, to: start) ?? start
        return VStack(alignment: .leading, spacing: 20) {
            Text("Seu compromisso")
                .font(.archivo(32))
                .tracking(-0.5)
            VStack(spacing: 0) {
                row("Começa", "Hoje, \(PTDate.short(start))")
                Divider().overlay(Theme.track)
                row("Termina", PTDate.short(end))
                Divider().overlay(Theme.track)
                row("Hábitos", "\(selected.count), todos os dias")
                Divider().overlay(Theme.track)
                row("Prazo diário", "Meia-noite")
                Divider().overlay(Theme.track)
                row("Segunda chance", "1 por mês")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Text("Se um dia ficar faltando um hábito, o Monk Mode acaba e você volta pro dia 1. Sem drama: você pode começar de novo na hora.")
                .font(.inter(16))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(label).foregroundStyle(Theme.muted)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
        .font(.inter(16))
        .padding(.vertical, 15)
    }

    // MARK: Ações

    private func load() {
        guard !loaded else { return }
        loaded = true
        let mine = store.data.habits
        let extra = Library.habits.filter { s in !mine.contains { $0.title == s.title } }
        options = mine + extra
        selected = Array(mine.map(\.id).prefix(Store.maxHabits))
    }

    private func begin() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        store.startMonk(with: chosen)
        dismiss()
    }
}

/// Aparece quando um dia acabou com hábito faltando.
struct MonkFailureView: View {
    @Environment(Store.self) private var store

    var body: some View {
        Group {
            if let run = store.data.monk, let failure = run.failure {
                content(run: run, failure: failure)
            } else {
                Color.clear
            }
        }
        .foregroundStyle(Theme.text)
        .screenBackground()
        .statusBarCover()
        .interactiveDismissDisabled()
    }

    @ViewBuilder
    private func content(run: MonkRun, failure: MonkFailure) -> some View {
        let failedDate = Store.date(fromKey: failure.dayKey) ?? Date()
        let canForgive = store.hasSecondChance(for: failedDate)
        let missing = failure.missing.compactMap { id in store.data.habits.first { $0.id == id } }
        let completed = max(failure.dayNumber - 1, 0)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if canForgive {
                    SectionLabel(text: "Monk Mode · dia \(store.monkDay)", color: Theme.accent)
                } else {
                    SectionLabel(text: "Monk Mode encerrado", color: Color(hex: 0xE06C5A))
                }
                Text(headline(failure: failure, count: missing.count))
                    .font(.archivo(36))
                    .tracking(-0.6)
                    .fixedSize(horizontal: false, vertical: true)

                if canForgive {
                    VStack(spacing: 8) {
                        ForEach(missing) { habit in
                            HStack(spacing: 12) {
                                CheckBox(done: false, size: 26)
                                Text(habit.title).font(.inter(16))
                                Spacer(minLength: 0)
                            }
                            .card(padding: 14)
                        }
                    }
                    Text("Pela regra, o Monk Mode acabaria aqui. Você ainda tem sua segunda chance deste mês. Usar agora?")
                        .font(.inter(16))
                        .foregroundStyle(Theme.muted)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Você já usou a segunda chance deste mês. O Monk Mode acabou no dia \(failure.dayNumber).")
                        .font(.inter(16))
                        .foregroundStyle(Theme.muted)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        stat("\(completed)", completed == 1 ? "dia completo" : "dias completos", Theme.text)
                        stat("\(max(store.monkRecord, completed))", "seu recorde", Theme.accent)
                        stat("\(run.attempt)ª", "tentativa", Theme.text)
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    Text("Cair faz parte. O que conta é voltar rápido.")
                        .font(.inter(16))
                        .foregroundStyle(Theme.muted)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if canForgive {
                    Button("Usar segunda chance e seguir") {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        store.useSecondChance()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Button("Aceitar e recomeçar do dia 1") {
                        store.acceptMonkFailure(restart: true)
                    }
                    .buttonStyle(OutlineButtonStyle())
                    Text("Se usar agora, a próxima só em \(PTDate.short(nextMonth(after: failedDate)))")
                        .font(.inter(14))
                        .foregroundStyle(Theme.muted)
                } else {
                    Button("Começar de novo hoje") {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        store.acceptMonkFailure(restart: true)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Button("Agora não") {
                        store.acceptMonkFailure(restart: false)
                    }
                    .buttonStyle(OutlineButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 16)
            .background(Theme.bg)
        }
    }

    private func headline(failure: MonkFailure, count: Int) -> String {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let when = Store.key(for: yesterday) == failure.dayKey ? "Ontem" : "No dia \(failure.dayNumber)"
        return count == 1 ? "\(when) ficou faltando 1 hábito." : "\(when) ficaram faltando \(count) hábitos."
    }

    private func nextMonth(after date: Date) -> Date {
        let cal = Calendar.current
        let start = cal.dateInterval(of: .month, for: date)?.start ?? date
        return cal.date(byAdding: .month, value: 1, to: start) ?? date
    }

    private func stat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.archivo(34))
                .foregroundStyle(color)
            Text(label)
                .font(.inter(13))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Botão com borda (opção secundária).
struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.inter(16, .medium))
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.chipBorder, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
