import SwiftUI

/// Aba Monk Mode: todos os hábitos dos 30 dias, cada um com a sua página.
struct MonkModeView: View {
    @Environment(Store.self) private var store
    @State private var showNew = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionLabel(text: "Dia \(min(store.dayNumber, store.phaseTarget)) de \(store.phaseTarget)", color: Theme.accent)
                            Text("Monk Mode")
                                .font(.archivo(34))
                                .tracking(-0.6)
                        }
                        Spacer()
                        Button {
                            showNew = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Theme.bg)
                                .frame(width: 48, height: 48)
                                .background(Circle().fill(store.canAddHabit ? Theme.accent : Theme.track))
                        }
                        .disabled(!store.canAddHabit)
                        .accessibilityLabel("Novo hábito")
                    }

                    ThinBar(value: Double(min(store.dayNumber, store.phaseTarget)) / Double(store.phaseTarget))

                    NavigationLink(value: MonkRoute.routine) {
                        routineCard
                    }
                    .buttonStyle(.plain)

                    if store.data.habits.isEmpty {
                        emptyState
                    } else {
                        ForEach(store.data.habits) { habit in
                            NavigationLink(value: MonkRoute.habit(habit.id)) {
                                HabitCard(habit: habit)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text(store.canAddHabit
                         ? "Poucos e firmes: até \(Store.maxHabits) hábitos além da rotina."
                         : "Você chegou ao limite de \(Store.maxHabits) hábitos. Poucos e firmes funciona melhor.")
                        .font(.inter(13))
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .foregroundStyle(Theme.text)
            .screenBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: MonkRoute.self) { route in
                switch route {
                case .routine: RoutineView()
                case .habit(let id): HabitDetailView(habitID: id)
                }
            }
        }
        .sheet(isPresented: $showNew) {
            NavigationStack { HabitFormView(existing: nil) }
        }
    }

    private var routineCard: some View {
        HStack(spacing: 16) {
            ProgressRing(value: store.data.routine.isEmpty ? 0 : Double(store.routineDoneCount) / Double(store.data.routine.count), color: Theme.done) {
                Image(systemName: "sunrise")
                    .font(.system(size: 20, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Rotina matinal")
                    .font(.archivo(19, bold: true))
                Text("Obrigatória · \(store.routineDoneCount) de \(store.data.routine.count) hoje")
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
        }
        .card(padding: 16, radius: 24)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nenhum hábito ainda")
                .font(.archivo(19, bold: true))
            Text("Escolha de 1 a \(Store.maxHabits) coisas para fazer (ou evitar) nos próximos 30 dias.")
                .font(.inter(14))
                .foregroundStyle(Theme.muted)
            Button("Criar o primeiro") { showNew = true }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
        }
        .card(padding: 18, radius: 24)
    }
}

enum MonkRoute: Hashable {
    case routine
    case habit(UUID)
}

/// Cartão de um hábito na lista.
struct HabitCard: View {
    @Environment(Store.self) private var store
    let habit: Habit

    var body: some View {
        let done = store.habitDoneDays(habit)
        HStack(spacing: 16) {
            ProgressRing(value: Double(done) / Double(habit.target), color: store.isHabitDone(habit) ? Theme.done : Theme.accent) {
                Image(systemName: habit.icon)
                    .font(.system(size: 20, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.archivo(19, bold: true))
                    .multilineTextAlignment(.leading)
                Text(habit.avoid ? "\(done) \(done == 1 ? "dia limpo" : "dias limpo") · Evitar" : "\(done) de \(habit.target) · \(habit.frequencyText)")
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
        }
        .card(padding: 16, radius: 24)
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
