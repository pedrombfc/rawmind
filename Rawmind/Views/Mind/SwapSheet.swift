import SwiftUI
import UIKit

/// "Vontade de pegar o celular?": escolher uma troca.
struct SwapSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var doneMessage: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "Em vez do celular", color: Theme.accent)
                        Text("O que você vai fazer agora?")
                            .font(.archivo(34))
                            .tracking(-0.6)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Todo espaço vazio virou scroll. Esse aqui é seu.")
                            .font(.inter(16))
                            .foregroundStyle(Theme.muted)
                    }

                    if !store.data.alternatives.isEmpty {
                        SectionLabel(text: "Seu plano")
                        FlowLayout(spacing: 10) {
                            ForEach(store.data.alternatives, id: \.self) { alt in
                                Chip(label: alt.prefix(1).uppercased() + alt.dropFirst(), selected: false) {
                                    quickSwap(alt)
                                }
                            }
                        }
                        Text("Toque quando fizer. Conta como uma troca.")
                            .font(.inter(13))
                            .foregroundStyle(Theme.muted)
                    }

                    SectionLabel(text: "Exercícios de mente")
                    VStack(spacing: 8) {
                        ForEach(MindKind.exercises) { kind in
                            NavigationLink(value: kind) {
                                ExerciseRow(kind: kind)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text(store.swapsToday == 1 ? "1 troca hoje" : "\(store.swapsToday) trocas hoje")
                        .font(.inter(14))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .foregroundStyle(Theme.text)
            .screenBackground()
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundStyle(Theme.muted)
                    .accessibilityLabel("Fechar")
                }
            }
            .navigationDestination(for: MindKind.self) { kind in
                if kind == .escrever {
                    WriteView(onDone: { dismiss() })
                } else {
                    MindExerciseView(kind: kind, onDone: { dismiss() })
                }
            }
            .overlay(alignment: .bottom) {
                if let doneMessage {
                    Text(doneMessage)
                        .font(.inter(15, .semibold))
                        .foregroundStyle(Theme.bg)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Theme.done))
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private func quickSwap(_ alt: String) {
        store.logMind(MindSession(kind: .outro, title: alt))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { doneMessage = "Boa. Troca feita." }
        let close = dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { close() }
    }
}

private struct ExerciseRow: View {
    let kind: MindKind

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: kind.icon)
                .font(.system(size: 20, weight: .medium))
                .frame(width: 48, height: 48)
                .background(Circle().fill(Theme.track))
            VStack(alignment: .leading, spacing: 2) {
                Text(kind.title)
                    .font(.inter(16, .semibold))
                Text(kind.subtitle)
                    .font(.inter(13))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Text("\(kind.defaultMinutes) min")
                .font(.inter(13))
                .foregroundStyle(Theme.muted)
        }
        .foregroundStyle(Theme.text)
        .card(padding: 14, radius: 20)
    }
}

/// Pensar, ler ou respirar com um timer.
struct MindExerciseView: View {
    @Environment(Store.self) private var store
    let kind: MindKind
    let onDone: () -> Void

    @State private var minutes: Int
    @State private var start: Date? = nil
    @State private var end: Date? = nil
    @State private var finishedSeconds: Int? = nil
    @State private var promptSeed = Int.random(in: 0..<100)
    @State private var note = ""

    init(kind: MindKind, onDone: @escaping () -> Void) {
        self.kind = kind
        self.onDone = onDone
        _minutes = State(initialValue: kind.defaultMinutes)
    }

    private var prompt: String { Prompts.pick(Prompts.think, promptSeed) }
    private var running: Bool { end != nil && finishedSeconds == nil }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            if let secs = finishedSeconds {
                finishedView(secs)
            } else if let end {
                runningView(end)
            } else {
                setupView
            }
            Spacer(minLength: 0)
            bottom
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .foregroundStyle(Theme.text)
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(running)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: Partes

    private var setupView: some View {
        VStack(spacing: 20) {
            SectionLabel(text: kind.title, color: Theme.accent)
            Text(kind == .pensar ? prompt : headline)
                .font(.archivo(30))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if kind == .pensar {
                Button("Outra pergunta") { promptSeed += 1 }
                    .font(.inter(15, .medium))
                    .foregroundStyle(Theme.muted)
            }
            Text(instructions)
                .font(.inter(16))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                ForEach(kind.minuteOptions, id: \.self) { m in
                    Chip(label: "\(m) min", selected: minutes == m) { minutes = m }
                }
            }
            .padding(.top, 8)
        }
    }

    private func runningView(_ end: Date) -> some View {
        TimelineView(.periodic(from: .now, by: kind == .respirar ? 0.05 : 1)) { context in
            let remaining = max(0, end.timeIntervalSince(context.date))
            let elapsed = context.date.timeIntervalSince(start ?? context.date)
            VStack(spacing: 28) {
                if kind == .pensar {
                    Text(prompt)
                        .font(.archivo(26))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if kind == .respirar {
                    BreathCircle(elapsed: elapsed)
                    Text(clock(remaining))
                        .font(.inter(17, .medium))
                        .monospacedDigit()
                        .foregroundStyle(Theme.muted)
                } else {
                    ZStack {
                        Circle().stroke(Theme.track, lineWidth: 6)
                        Circle()
                            .trim(from: 0, to: 1 - remaining / Double(max(minutes, 1) * 60))
                            .stroke(Theme.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text(clock(remaining))
                            .font(.archivo(50))
                            .monospacedDigit()
                    }
                    .frame(width: 220, height: 220)
                }
                Text(runningHint)
                    .font(.inter(15))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .onChange(of: remaining <= 0) { _, over in
                if over { finish() }
            }
        }
    }

    private func finishedView(_ secs: Int) -> some View {
        VStack(spacing: 16) {
            Text("Feito.")
                .font(.archivo(44))
            Text("\(durationText(secs)) longe do scroll.")
                .font(.inter(16))
                .foregroundStyle(Theme.muted)
            if kind != .respirar {
                TextField("", text: $note, prompt: Text(kind == .pensar ? "Quer anotar o que pensou? (opcional)" : "O que ficou na cabeça? (opcional)").foregroundStyle(Theme.muted), axis: .vertical)
                    .font(.inter(16))
                    .lineLimit(2...6)
                    .padding(14)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.top, 8)
            }
        }
    }

    @ViewBuilder
    private var bottom: some View {
        if let secs = finishedSeconds {
            Button("Guardar troca") {
                let text = note.trimmingCharacters(in: .whitespacesAndNewlines)
                store.logMind(MindSession(kind: kind, seconds: secs, text: text, title: kind == .pensar ? prompt : ""))
                onDone()
            }
            .buttonStyle(PrimaryButtonStyle())
        } else if running {
            Button("Terminei antes") { finish() }
                .font(.inter(16, .medium))
                .foregroundStyle(Theme.muted)
                .frame(height: 56)
        } else {
            Button("Começar") {
                let now = Date()
                start = now
                end = now.addingTimeInterval(TimeInterval(minutes * 60))
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    // MARK: Textos

    private var headline: String {
        switch kind {
        case .ler: return "Pega um livro."
        case .respirar: return "Um minuto só seu."
        case .meditar: return "Fecha os olhos."
        default: return kind.title
        }
    }

    private var instructions: String {
        switch kind {
        case .pensar: return "Celular virado pra baixo. Não precisa chegar a resposta nenhuma. Deixa a cabeça andar."
        case .ler: return "De papel, de preferência. Uma página já conta."
        case .respirar: return "Inspira em 4 segundos, solta em 6. Acompanha o círculo."
        case .meditar: return "Senta confortável e presta atenção no ar entrando e saindo. Se a cabeça fugir, volta pra respiração."
        default: return ""
        }
    }

    private var runningHint: String {
        switch kind {
        case .pensar: return "Se a cabeça fugir da pergunta, tudo bem. Só não pega o celular."
        case .ler: return "Celular virado pra baixo. O tempo é do livro."
        case .meditar: return "Olhos fechados. O celular vibra quando acabar."
        default: return ""
        }
    }

    // MARK: Ações

    private func finish() {
        guard finishedSeconds == nil else { return }
        let secs = Int(Date().timeIntervalSince(start ?? Date()))
        finishedSeconds = max(secs, 0)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func clock(_ seconds: TimeInterval) -> String {
        let s = Int(seconds.rounded(.up))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    private func durationText(_ secs: Int) -> String {
        if secs < 60 { return "\(secs) segundos" }
        let m = secs / 60
        return m == 1 ? "1 minuto" : "\(m) minutos"
    }
}

/// Círculo que cresce (inspira 4 s) e diminui (solta 6 s).
private struct BreathCircle: View {
    let elapsed: TimeInterval

    var body: some View {
        let cycle = elapsed.truncatingRemainder(dividingBy: 10)
        let inhaling = cycle < 4
        let scale = inhaling ? 0.55 + 0.45 * (cycle / 4) : 1 - 0.45 * ((cycle - 4) / 6)
        ZStack {
            Circle()
                .fill(Theme.accent.opacity(0.18))
                .overlay(Circle().strokeBorder(Theme.accent, lineWidth: 3))
                .scaleEffect(scale)
            Text(inhaling ? "Inspira" : "Solta")
                .font(.archivo(26))
        }
        .frame(width: 240, height: 240)
    }
}

/// Escrever em vez de rolar o feed.
struct WriteView: View {
    @Environment(Store.self) private var store
    let onDone: () -> Void

    @State private var text = ""
    @State private var seed = Int.random(in: 0..<100)
    @State private var opened = Date()
    @FocusState private var focused: Bool

    private var prompt: String { Prompts.pick(Prompts.write, seed) }
    private var words: Int { text.split { $0.isWhitespace || $0.isNewline }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(text: "Escrever", color: Theme.accent)
            Text(prompt)
                .font(.archivo(28))
                .fixedSize(horizontal: false, vertical: true)
            TextEditor(text: $text)
                .font(.inter(17))
                .scrollContentBackground(.hidden)
                .padding(12)
                .frame(minHeight: 180)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .focused($focused)
            Text("\(words) \(words == 1 ? "palavra" : "palavras") · fica guardado só no seu celular")
                .font(.inter(13))
                .foregroundStyle(Theme.muted)
            Button("Guardar no caderno") {
                store.logMind(MindSession(
                    kind: .escrever,
                    seconds: Int(Date().timeIntervalSince(opened)),
                    text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                    title: prompt
                ))
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onDone()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(words < 3)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .foregroundStyle(Theme.text)
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Outra pergunta") { seed += 1 }
                    .foregroundStyle(Theme.muted)
            }
        }
        .onAppear { focused = true }
    }
}

/// Caderno: tudo o que a pessoa escreveu.
struct JournalView: View {
    @Environment(Store.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Seu caderno")
                    .font(.archivo(34))
                    .tracking(-0.6)
                Text("Tudo o que você escreveu em vez de rolar o feed. Fica só no seu celular.")
                    .font(.inter(15))
                    .foregroundStyle(Theme.muted)
                    .padding(.bottom, 4)
                if store.journal.isEmpty {
                    Text("Ainda vazio. Na próxima vontade de pegar o celular, escreve três linhas.")
                        .font(.inter(15))
                        .foregroundStyle(Theme.muted)
                        .card(padding: 18, radius: 20)
                }
                ForEach(store.journal) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(PTDate.short(entry.date)) · \(entry.kind == .escrever ? "Escrita" : entry.kind.title)")
                            .font(.inter(12, .semibold))
                            .foregroundStyle(Theme.muted)
                        if !entry.title.isEmpty {
                            Text(entry.title)
                                .font(.inter(14))
                                .foregroundStyle(Theme.accent)
                        }
                        Text(entry.text)
                            .font(.inter(16))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .card(padding: 18, radius: 20)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .foregroundStyle(Theme.text)
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
    }
}

/// "Outra coisa": anotar o que você fez no lugar do celular.
struct OtherSwapView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        Form {
            Section {
                TextField("Ex.: Saí pra caminhar, arrumei o quarto", text: $text, axis: .vertical)
                    .lineLimit(1...3)
            } header: {
                Text("O que você fez em vez do celular?")
            }
            .listRowBackground(Theme.card)

            if !store.data.alternatives.isEmpty {
                Section("Do seu plano") {
                    ForEach(store.data.alternatives, id: \.self) { alt in
                        Button {
                            save(alt)
                        } label: {
                            Text(alt.prefix(1).uppercased() + alt.dropFirst())
                                .foregroundStyle(Theme.text)
                        }
                    }
                }
                .listRowBackground(Theme.card)
            }
        }
        .font(.inter(16))
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Outra coisa")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Registrar") { save(text) }
                    .fontWeight(.semibold)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func save(_ value: String) {
        let t = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        store.logMind(MindSession(kind: .outro, title: t))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
