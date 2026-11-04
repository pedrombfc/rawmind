import SwiftUI
import UIKit

/// Tela "Hoje": tempo de tela ganho, rotina matinal, cartão do Monk Mode
/// e tarefas "em vez do celular" por seção. Foco no cadeado do canto.
struct TodayView: View {
    @Environment(Store.self) private var store
    var openMonk: () -> Void = {}
    @State private var showFocus = false
    @State private var showOther = false
    @State private var path = NavigationPath()
    @State private var screenForm: ScreenTimeCard.ScreenFormMode? = nil

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    routineCard
                    monkCard
                    activitiesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .screenBackground()
            .statusBarCover()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { value in
                if value == "routine" { RoutineView() }
            }
            .navigationDestination(for: MindKind.self) { kind in
                switch kind {
                case .ler: ReadLogView(onDone: { path = NavigationPath() })
                case .escrever: WriteView(onDone: { path = NavigationPath() })
                default: MindExerciseView(kind: kind, onDone: { path = NavigationPath() })
                }
            }
            .navigationDestination(for: Activity.self) { activity in
                ActivityTaskView(activity: activity, onDone: { path = NavigationPath() })
            }
            .navigationDestination(for: ActivityCategory.self) { category in
                ActivityCategoryView(category: category)
            }
        }
        .sheet(isPresented: $showFocus) {
            FocusView()
                .trackedModal()
        }
        .sheet(isPresented: $showOther) {
            NavigationStack { OtherSwapView() }
                .presentationDetents([.medium, .large])
                .trackedModal()
        }
        .sheet(item: $screenForm) { mode in
            NavigationStack { ScreenTimeForm(isBaseline: mode == .baseline) }
                .trackedModal()
        }
    }

    // MARK: Partes

    /// Topo: data e quanto tempo de celular por dia você cortou desde antes do Rawmind.
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text(PTDate.long(Date()))
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
                Spacer(minLength: 8)
                lockButton
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
                                Text("Livres por semana")
                                    .font(.inter(12))
                                    .foregroundStyle(Theme.muted)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Text(Store.durationText(saved * 7))
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
                    weekUpdateLink
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
                    weekUpdateLink
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

    /// Sessão de foco (Lock in), no canto de cima.
    private var lockButton: some View {
        Button {
            showFocus = true
        } label: {
            Image(systemName: "lock.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.bg)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.accent))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Lock in: sessão de foco")
    }

    @ViewBuilder
    private var weekUpdateLink: some View {
        if store.needsScreenUpdate {
            Button { screenForm = .week } label: {
                Text("Anotar o tempo de tela desta semana →")
                    .font(.inter(14, .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
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

    // MARK: Em vez do celular

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Em vez do celular")
                .font(.archivo(28, bold: true))
                .tracking(-0.5)
                .padding(.top, 4)
            ForEach(ActivityCategory.allCases) { category in
                categoryRow(category)
            }
            otherButton
        }
    }

    private func categoryRow(_ category: ActivityCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(value: category) {
                HStack(spacing: 6) {
                    Text(category.title)
                        .font(.archivo(20, bold: true))
                        .foregroundStyle(Theme.text)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.muted)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Abre a lista completa")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(category.activities) { activity in
                        ActivityLink(activity: activity) {
                            ActivityCard(activity: activity)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .safeAreaPadding(.horizontal, 20)
            .padding(.horizontal, -20)
        }
    }

    /// "Outra coisa": anotar algo que não está nas listas.
    private var otherButton: some View {
        Button { showOther = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.track))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Fiz outra coisa")
                        .font(.inter(16, .semibold))
                    Text("Anote o que você fez em vez do celular")
                        .font(.inter(13))
                        .foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(Theme.text)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Theme.track, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var routineSubtitle: String {
        if store.routineComplete { return "Feita. O dia é seu." }
        let missing = store.data.routine.filter { !store.isRoutineItemDone($0) }.map(\.title)
        if missing.count > 2 { return "Começa às \(store.routineTimeText). Toque para abrir." }
        return "Falta: " + missing.joined(separator: ", ")
    }

    /// Cartão do Monk Mode (abre a aba). Os hábitos em si ficam lá.
    private var monkCard: some View {
        Button(action: openMonk) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(monkTitle)
                        .font(.archivo(19, bold: true))
                        .foregroundStyle(Theme.text)
                    Text(monkSubtitle)
                        .font(.inter(14))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if store.monkActive {
                        HStack(spacing: 5) {
                            ForEach(store.monkHabits) { habit in
                                Capsule()
                                    .fill(store.isHabitDone(habit) ? Theme.done : Theme.track)
                                    .frame(height: 5)
                            }
                        }
                        .padding(.top, 6)
                    }
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
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Theme.track, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var monkTitle: String {
        if store.monkActive { return "Monk Mode · dia \(min(store.monkDay, Store.monkDays))" }
        if store.monkCompleted { return "Monk Mode completo" }
        return "Monk Mode parado"
    }

    private var monkSubtitle: String {
        if store.monkActive {
            let total = store.monkHabits.count
            let missing = total - store.monkDoneToday
            return missing <= 0
                ? "Tudo feito hoje. Amanhã é o dia \(min(store.monkDay + 1, Store.monkDays))."
                : "Faltam \(missing) de \(total) hábitos. Prazo: meia-noite."
        }
        if store.monkCompleted { return "30 dias feitos. Escreva o que mudou." }
        return "\(Store.monkDays) dias, \(Store.minHabits) hábitos ou mais, sem desculpa."
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
