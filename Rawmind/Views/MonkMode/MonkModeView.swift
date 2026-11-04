import SwiftUI
import UIKit

/// Aba Monk Mode: parado (botão de iniciar), ativo (hábitos de hoje até a meia-noite) ou completo.
struct MonkModeView: View {
    @Environment(Store.self) private var store
    @State private var showStart = false

    var body: some View {
        NavigationStack {
            Group {
                if store.monkCompleted {
                    MonkCompletedView { showStart = true }
                } else if store.monkActive {
                    MonkActiveView()
                } else {
                    MonkIntroView { showStart = true }
                }
            }
            .foregroundStyle(Theme.text)
            .screenBackground()
            .statusBarCover()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: MonkRoute.self) { route in
                switch route {
                case .habit(let id): HabitDetailView(habitID: id)
                }
            }
        }
        .fullScreenCover(isPresented: $showStart) {
            MonkStartFlow()
        }
    }
}

enum MonkRoute: Hashable {
    case habit(UUID)
}

// MARK: - Parado

/// Antes de começar: as regras e o botão "Iniciar Monk Mode".
private struct MonkIntroView: View {
    @Environment(Store.self) private var store
    let start: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionLabel(text: "Desafio de \(Store.monkDays) dias", color: Theme.accent)
                VStack(alignment: .leading, spacing: -8) {
                    Text("Monk")
                    Text("Mode")
                }
                .font(.archivo(56))
                .tracking(-1.6)
                Text("\(Store.monkDays) dias. No mínimo \(Store.minHabits) hábitos. Todos, todo dia. Sem desculpa.")
                    .font(.inter(16))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 16) {
                    rule(1, "Escolha \(Store.minHabits) hábitos ou mais", "Fazer ou evitar. Eles ficam travados até o fim.")
                    rule(2, "Marque todos até a meia-noite", "Faltou um? O Monk Mode acaba e volta pro dia 1.")
                    rule(3, "1 segunda chance por mês", "Uma falha por mês você pode perdoar. Só uma.")
                }
                .card(padding: 20, radius: 24)

                Text("A rotina matinal continua na tela Hoje, com ou sem Monk Mode.")
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button(action: start) {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Iniciar Monk Mode")
                    }
                    .font(.archivo(20))
                    .foregroundStyle(Theme.bg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                if store.monkRecord > 0 {
                    Text("Melhor tentativa: \(store.monkRecord) \(store.monkRecord == 1 ? "dia" : "dias")")
                        .font(.inter(14))
                        .foregroundStyle(Theme.muted)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(Theme.bg)
        }
    }

    private func rule(_ n: Int, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text("\(n)")
                .font(.archivo(20))
                .foregroundStyle(Theme.accent)
                .frame(width: 18, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.inter(16, .semibold))
                Text(detail)
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Ativo

/// Monk Mode rodando: dia, prazo até a meia-noite e os hábitos de hoje.
private struct MonkActiveView: View {
    @Environment(Store.self) private var store

    var body: some View {
        let day = min(store.monkDay, Store.monkDays)
        let habits = store.monkHabits
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        SectionLabel(text: "Monk Mode ativo", color: Theme.accent)
                        (Text("Dia \(day)").foregroundColor(Theme.text)
                         + Text(" de \(Store.monkDays)").font(.archivo(22)).foregroundColor(Theme.muted))
                            .font(.archivo(44))
                            .tracking(-0.8)
                    }
                    Spacer(minLength: 8)
                    chancePill
                        .padding(.top, 2)
                }

                ThinBar(value: Double(day) / Double(Store.monkDays))

                TimelineView(.periodic(from: .now, by: 30)) { context in
                    deadlineCard(now: context.date)
                }

                SectionLabel(text: "Hoje · \(store.monkDoneToday) de \(habits.count)")
                    .padding(.top, 4)

                ForEach(habits) { habit in
                    MonkHabitRow(habit: habit)
                }

                Text("Toque num hábito para ver o calendário e as notas")
                    .font(.inter(13))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)

                MonkDaysGrid()
                    .padding(.top, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    private var chancePill: some View {
        let has = store.hasSecondChance()
        return HStack(spacing: 6) {
            Circle().fill(has ? Theme.done : Theme.muted).frame(width: 8, height: 8)
            Text(has ? "1 segunda chance" : "Segunda chance usada")
                .font(.inter(13, .medium))
                .foregroundStyle(has ? Theme.text : Theme.muted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(Theme.card))
    }

    @ViewBuilder
    private func deadlineCard(now: Date) -> some View {
        let missing = store.monkHabits.count - store.monkDoneToday
        if missing <= 0 {
            HStack(spacing: 14) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.done)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Tudo feito hoje")
                        .font(.archivo(19, bold: true))
                    Text("Amanhã é o dia \(min(store.monkDay + 1, Store.monkDays)).")
                        .font(.inter(14))
                        .foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 0)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.doneBg)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        } else {
            let minutes = max(Int((store.midnight.timeIntervalSince(now) / 60).rounded(.up)), 0)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(missing == 1 ? "Falta 1 hábito" : "Faltam \(missing) hábitos")
                        .font(.archivo(19, bold: true))
                    Text("Prazo: meia-noite")
                        .font(.inter(14))
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(Store.durationText(minutes))
                        .font(.archivo(28))
                        .foregroundStyle(Theme.accent)
                    Text("restantes")
                        .font(.inter(13))
                        .foregroundStyle(Theme.muted)
                }
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
    }
}

/// Uma linha de hábito: a caixinha marca, o resto abre a página do hábito.
private struct MonkHabitRow: View {
    @Environment(Store.self) private var store
    let habit: Habit

    var body: some View {
        let done = store.isHabitDone(habit)
        HStack(spacing: 4) {
            Button {
                withAnimation(.snappy) { store.toggleHabit(habit) }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                CheckBox(done: done, size: 26)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(done ? "Desmarcar \(habit.title)" : "Marcar \(habit.title)")

            NavigationLink(value: MonkRoute.habit(habit.id)) {
                HStack(spacing: 10) {
                    Text(habit.title)
                        .font(.inter(16, .medium))
                        .foregroundStyle(done ? Theme.muted : Theme.text)
                        .strikethrough(done, color: Theme.muted)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    Text(habit.sideText)
                        .font(.inter(13))
                        .foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 6)
        .padding(.trailing, 16)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Completo

/// Os 30 dias acabaram: hora de escrever a conclusão de cada hábito.
private struct MonkCompletedView: View {
    @Environment(Store.self) private var store
    let startNew: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(text: "Monk Mode completo", color: Theme.done)
                (Text("\(Store.monkDays)").foregroundColor(Theme.text)
                 + Text(" de \(Store.monkDays)").font(.archivo(22)).foregroundColor(Theme.muted))
                    .font(.archivo(44))
                ThinBar(value: 1, color: Theme.done)
                Text("Você fez todos os hábitos, todos os dias. Agora escreva o que mudou em cada um.")
                    .font(.inter(16))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(store.monkHabits) { habit in
                    NavigationLink(value: MonkRoute.habit(habit.id)) {
                        HStack(spacing: 14) {
                            Image(systemName: habit.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Theme.track))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(habit.title)
                                    .font(.inter(16, .semibold))
                                    .multilineTextAlignment(.leading)
                                Text(store.conclusion(for: habit).map { "Conclusão: \($0.decision.rawValue)" } ?? "Escrever conclusão")
                                    .font(.inter(14))
                                    .foregroundStyle(store.conclusion(for: habit) == nil ? Theme.accent : Theme.muted)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
                        }
                        .foregroundStyle(Theme.text)
                        .card(padding: 14, radius: 20)
                    }
                    .buttonStyle(.plain)
                }

                MonkDaysGrid()
                    .padding(.top, 8)

                Button("Começar outro Monk Mode", action: startNew)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }
}

/// "Seus 30 dias": um quadrado por dia, mais dias completos, recorde e tentativa.
private struct MonkDaysGrid: View {
    @Environment(Store.self) private var store

    var body: some View {
        let completed = store.monkCompletedDays
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Seus \(Store.monkDays) dias")
            VStack(spacing: 8) {
                ForEach(0..<(Store.monkDays / 6), id: \.self) { r in
                    HStack(spacing: 8) {
                        ForEach(1...6, id: \.self) { c in
                            let n = r * 6 + c
                            cell(n, store.monkDayState(n))
                        }
                    }
                }
            }
            HStack(spacing: 14) {
                legend(Theme.done, "Tudo feito")
                legend(Theme.accent.opacity(0.35), "Segunda chance")
                legend(Theme.accent, "Hoje", ring: true)
            }
            .font(.inter(13))
            .foregroundStyle(Theme.muted)

            HStack(spacing: 10) {
                tile("\(completed)", completed == 1 ? "dia completo" : "dias completos", Theme.text)
                tile("\(max(store.monkRecord, completed))", "seu recorde", Theme.accent)
                tile("\(store.data.monk?.attempt ?? 1)ª", "tentativa", Theme.text)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func cell(_ n: Int, _ state: Store.MonkDayState) -> some View {
        let fill: Color
        let textColor: Color
        switch state {
        case .done: fill = Theme.done; textColor = Theme.bg
        case .forgiven: fill = Theme.accent.opacity(0.35); textColor = Theme.text
        case .today: fill = Theme.card; textColor = Theme.text
        case .missed: fill = Theme.track; textColor = Theme.muted
        case .future: fill = Theme.card.opacity(0.6); textColor = Theme.muted.opacity(0.6)
        }
        return ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(fill)
            if state == .today {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Theme.accent, lineWidth: 2)
            }
            Text("\(n)")
                .font(.inter(14, .semibold))
                .foregroundStyle(textColor)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Dia \(n)")
    }

    private func legend(_ color: Color, _ label: String, ring: Bool = false) -> some View {
        HStack(spacing: 6) {
            if ring {
                RoundedRectangle(cornerRadius: 3).strokeBorder(color, lineWidth: 2).frame(width: 12, height: 12)
            } else {
                RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 12, height: 12)
            }
            Text(label)
        }
    }

    private func tile(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.archivo(22, bold: true))
                .foregroundStyle(color)
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
}

/// Anel de progresso com um ícone no meio.
struct ProgressRing<Content: View>: View {
    let value: Double
    var color: Color = Theme.accent
    var size: CGFloat = 60
    var lineWidth: CGFloat = 5
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Circle().stroke(Theme.track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(value, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            content()
                .foregroundStyle(Theme.text)
        }
        .frame(width: size, height: size)
    }
}
