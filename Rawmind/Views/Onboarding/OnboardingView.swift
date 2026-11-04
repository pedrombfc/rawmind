import SwiftUI
import UIKit

/// Primeira vez no app: 6 passos até "assinar" a rotina. O Monk Mode começa depois, na aba dele.
struct OnboardingView: View {
    @Environment(Store.self) private var store

    @State private var step = 0
    @State private var routine: [RoutineItem] = Array(Library.routine.prefix(3))
    @State private var wakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var alternatives: [String] = ["ler uma página"]
    @State private var screenH = 4
    @State private var screenM = 0
    @State private var instaH = 1
    @State private var instaM = 0
    @State private var skipBaseline = false

    private let totalSteps = 6

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 24)
                .padding(.top, 8)

            ScrollView {
                Group {
                    switch step {
                    case 0: ManifestoStep()
                    case 1: BaselineStep(totalH: $screenH, totalM: $screenM, instaH: $instaH, instaM: $instaM) {
                        skipBaseline = true
                        step += 1
                    }
                    case 2: RoutineStep(selected: $routine)
                    case 3: TimeStep(time: $wakeTime)
                    case 4: AlternativesStep(selected: $alternatives)
                    default: CommitStep(
                        routineCount: routine.count,
                        timeText: timeText,
                        alternative: alternatives.first ?? "—"
                    )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .id(step)
                .transition(.opacity)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .background(Theme.bg)
            }
        }
        .screenBackground()
        .foregroundStyle(Theme.text)
        .animation(.easeInOut(duration: 0.25), value: step)
    }

    private var topBar: some View {
        HStack {
            if step == 0 {
                (Text("rawmind").foregroundColor(Theme.text) + Text(".").foregroundColor(Theme.accent))
                    .font(.archivo(22))
            } else {
                Button {
                    step -= 1
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 44, height: 44, alignment: .leading)
                }
                .foregroundStyle(Theme.text)
                .accessibilityLabel("Voltar")
            }
            Spacer()
            Text("\(step + 1) de \(totalSteps)")
                .font(.inter(13))
                .foregroundStyle(Theme.muted)
        }
        .frame(height: 44)
    }

    @ViewBuilder
    private var bottomBar: some View {
        VStack(spacing: 20) {
            if step < totalSteps - 1 {
                StepBars(total: totalSteps, filled: step + 1)
                Button(buttonTitle) {
                    if step == 1 { skipBaseline = false }
                    step += 1
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(step == 2 && routine.isEmpty)
            } else {
                HoldToCommitButton { finish() }
                Text("Segure por 3 segundos para assinar")
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
            }
        }
    }

    private var buttonTitle: String {
        switch step {
        case 0: return "Bora começar"
        default: return "Continuar"
        }
    }

    private var timeText: String {
        let c = Calendar.current.dateComponents([.hour, .minute], from: wakeTime)
        return String(format: "%d:%02d", c.hour ?? 7, c.minute ?? 0)
    }

    private func finish() {
        let c = Calendar.current.dateComponents([.hour, .minute], from: wakeTime)
        let hour = c.hour ?? 7
        let minute = c.minute ?? 0
        let chosenRoutine = routine
        let chosenAlternatives = alternatives
        let baseline: ScreenTimeEntry? = skipBaseline ? nil : ScreenTimeEntry(totalMinutes: screenH * 60 + screenM, instagramMinutes: instaH * 60 + instaM)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        store.update { d in
            d.routine = chosenRoutine
            d.routineHour = hour
            d.routineMinute = minute
            d.alternatives = chosenAlternatives
            if let baseline { d.screenBaseline = baseline }
            d.startDate = Calendar.current.startOfDay(for: Date())
            d.onboarded = true
        }
        Notifications.requestPermission { granted in
            if granted { Notifications.scheduleMorning(hour: hour, minute: minute) }
        }
    }
}

// MARK: - Passos

private struct StepTitle: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.archivo(34))
                .tracking(-0.6)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(.inter(16))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct ManifestoStep: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 60)
            Text("Quando foi a última vez que você ficou 5 minutos sem o celular?")
                .font(.archivo(40))
                .tracking(-1)
                .fixedSize(horizontal: false, vertical: true)
            Text("Fila, banheiro, esperando uma resposta. Todo espaço vazio virou scroll. O Rawmind não só tira o celular da sua mão: ele coloca algo melhor no lugar.")
                .font(.inter(17))
                .foregroundStyle(Theme.muted)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct BaselineStep: View {
    @Binding var totalH: Int
    @Binding var totalM: Int
    @Binding var instaH: Int
    @Binding var instaM: Int
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            StepTitle(
                title: "Seu ponto de partida",
                subtitle: "Quanto tempo você passa no celular por dia? Veja em Ajustes > Tempo de Uso > Ver toda a atividade. Daqui a umas semanas a gente compara."
            )
            VStack(alignment: .leading, spacing: 4) {
                Text("Celular no total, por dia")
                    .font(.inter(14, .semibold))
                    .foregroundStyle(Theme.muted)
                DurationPicker(hours: $totalH, minutes: $totalM)
            }
            .card(padding: 14)
            VStack(alignment: .leading, spacing: 4) {
                Text("Instagram (ou a rede que mais te prende)")
                    .font(.inter(14, .semibold))
                    .foregroundStyle(Theme.muted)
                DurationPicker(hours: $instaH, minutes: $instaM)
            }
            .card(padding: 14)
            Button("Não sei agora, anoto depois", action: onSkip)
                .font(.inter(15, .medium))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct RoutineStep: View {
    @Binding var selected: [RoutineItem]
    @State private var custom = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            StepTitle(
                title: "Monte sua rotina matinal",
                subtitle: "É o único hábito obrigatório. Você escolhe o que entra. Comece com 3 a 5 coisas que cabem na sua manhã."
            )

            VStack(spacing: 8) {
                ForEach(options) { item in
                    let on = selected.contains { $0.id == item.id }
                    Button {
                        toggle(item)
                    } label: {
                        HStack(spacing: 14) {
                            CheckBox(done: on, size: 26)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title)
                                    .font(.inter(16, .medium))
                                    .foregroundStyle(Theme.text)
                                if !item.why.isEmpty {
                                    Text(item.why)
                                        .font(.inter(13))
                                        .foregroundStyle(Theme.muted)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .card(padding: 14)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                TextField("", text: $custom, prompt: Text("Criar o seu item").foregroundStyle(Theme.muted))
                    .font(.inter(16))
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .submitLabel(.done)
                    .onSubmit(addCustom)
                Button("Adicionar", action: addCustom)
                    .font(.inter(15, .semibold))
                    .foregroundStyle(Theme.accent)
                    .disabled(custom.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Text("\(selected.count) escolhido\(selected.count == 1 ? "" : "s")")
                .font(.inter(14))
                .foregroundStyle(Theme.muted)
        }
    }

    /// Sugestões + itens que a pessoa criou.
    private var options: [RoutineItem] {
        let customOnes = selected.filter { s in !Library.routine.contains { $0.id == s.id } }
        return Library.routine + customOnes
    }

    private func toggle(_ item: RoutineItem) {
        if let i = selected.firstIndex(where: { $0.id == item.id }) {
            selected.remove(at: i)
        } else {
            selected.append(item)
        }
    }

    private func addCustom() {
        let t = custom.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        selected.append(RoutineItem(title: t, why: ""))
        custom = ""
    }
}

private struct TimeStep: View {
    @Binding var time: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            StepTitle(
                title: "A que horas começa a sua manhã?",
                subtitle: "Nesse horário a gente te lembra da rotina. Dá pra mudar depois em Ajustes."
            )
            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .environment(\.locale, Locale(identifier: "pt_BR"))
        }
    }
}

private struct AlternativesStep: View {
    @Binding var selected: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            StepTitle(
                title: "Em vez de abrir o Instagram, eu vou…",
                subtitle: "Escolha até 3, de preferência longe da tela. Dizer o que fazer no lugar funciona melhor do que só dizer “não”."
            )
            FlowLayout(spacing: 10) {
                ForEach(Library.alternatives, id: \.self) { option in
                    Chip(label: option.prefix(1).uppercased() + option.dropFirst(), selected: selected.contains(option)) {
                        if let i = selected.firstIndex(of: option) {
                            selected.remove(at: i)
                        } else {
                            selected = Array((selected + [option]).suffix(3))
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Seu plano")
                    .font(.inter(13))
                    .foregroundStyle(Theme.muted)
                (Text("Se eu for abrir o Instagram, então eu vou ")
                 + Text(selected.isEmpty ? "…" : selected.joined(separator: " ou ")).foregroundColor(Theme.accent)
                 + Text("."))
                    .font(.inter(16))
                    .lineSpacing(3)
            }
            .card()
        }
    }
}

private struct CommitStep: View {
    let routineCount: Int
    let timeText: String
    let alternative: String

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            StepTitle(title: "Seu protocolo está pronto.")
            VStack(spacing: 0) {
                row("Fase 1", "30 dias, começa hoje")
                Divider().overlay(Theme.track)
                row("Rotina matinal", "\(routineCount) \(routineCount == 1 ? "item" : "itens"), às \(timeText)")
                Divider().overlay(Theme.track)
                row("Monk Mode", "quando você quiser")
                Divider().overlay(Theme.track)
                row("Em vez de abrir", alternative)
                Divider().overlay(Theme.track)
                row("Escudo", "chega numa próxima versão")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Text("Você tem 2 dias de reserva por semana. Errar um dia não apaga nada: o que conta é voltar.")
                .font(.inter(15))
                .foregroundStyle(Theme.muted)
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
        .font(.inter(15))
        .padding(.vertical, 16)
    }
}

/// Círculo "lock in": segurar 3 segundos para assinar.
struct HoldToCommitButton: View {
    let onComplete: () -> Void
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            Circle().stroke(Theme.track, lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .fill(Theme.accent)
                .padding(12)
            Text("lock in")
                .font(.archivo(20))
                .foregroundStyle(Theme.bg)
        }
        .frame(width: 132, height: 132)
        .contentShape(Circle())
        .onLongPressGesture(minimumDuration: 3, maximumDistance: 60) {
            onComplete()
        } onPressingChanged: { pressing in
            if pressing {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.linear(duration: 3)) { progress = 1 }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Segure para assinar o protocolo")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onComplete() }
    }
}
