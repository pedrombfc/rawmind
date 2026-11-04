import SwiftUI

/// Criar ou editar um hábito do Monk Mode. Todo hábito é diário, durante os 30 dias.
struct HabitFormView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let existing: Habit?
    /// Usado ao iniciar o Monk Mode: devolve o hábito novo em vez de salvar.
    var onCreate: ((Habit) -> Void)? = nil

    @State private var title = ""
    @State private var why = ""
    @State private var avoid = false
    @State private var icon = "flame"
    @State private var reminders: [HabitReminder] = []
    @State private var showIcons = false
    @State private var loaded = false

    /// Durante o Monk Mode o nome e o tipo ficam travados.
    private var locked: Bool { existing != nil && store.monkActive }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 10) {
                    Button {
                        showIcons = true
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            Image(systemName: icon)
                                .font(.system(size: 44, weight: .regular))
                                .foregroundStyle(Theme.text)
                                .frame(width: 112, height: 112)
                                .background(Circle().fill(Theme.card))
                                .overlay(Circle().strokeBorder(Theme.track, lineWidth: 2))
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Theme.bg)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Theme.accent))
                                .overlay(Circle().strokeBorder(Theme.bg, lineWidth: 3))
                                .offset(x: 2, y: -2)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Escolher ícone")
                    Text("Toque para escolher o ícone")
                        .font(.inter(14))
                        .foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)

            Section {
                Picker("Tipo", selection: $avoid) {
                    Text("Fazer").tag(false)
                    Text("Evitar").tag(true)
                }
                .pickerStyle(.segmented)
                .disabled(locked)
                TextField(avoid ? "Ex.: Sem redes antes do meio-dia" : "Ex.: Ler 10 páginas", text: $title)
                    .disabled(locked)
                    .foregroundStyle(locked ? Theme.muted : Theme.text)
            } header: {
                Text("Nome")
            } footer: {
                VStack(alignment: .leading, spacing: 10) {
                    if existing == nil && onCreate == nil && !suggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions) { s in
                                    Button { apply(s) } label: {
                                        Text(s.title)
                                            .font(.inter(14, title == s.title ? .semibold : .regular))
                                            .foregroundStyle(title == s.title ? Theme.bg : Theme.text)
                                            .padding(.horizontal, 13)
                                            .frame(height: 34)
                                            .background(Capsule().fill(title == s.title ? Theme.accent : Color.clear))
                                            .overlay(Capsule().strokeBorder(title == s.title ? Theme.accent : Theme.chipBorder, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    if locked {
                        Text("O nome fica travado até o fim do Monk Mode.")
                    } else {
                        Text(avoid
                             ? "Todo dia, durante os 30 dias do Monk Mode. À noite você confirma: \"hoje eu me mantive\"."
                             : "Todo dia, durante os 30 dias do Monk Mode.")
                    }
                }
                .padding(.top, 4)
            }
            .listRowBackground(Theme.card)

            Section("O que você espera que mude?") {
                TextField("Ex.: Dormir melhor e ter mais energia", text: $why, axis: .vertical)
                    .lineLimit(2...4)
            }
            .listRowBackground(Theme.card)

            Section {
                ForEach($reminders) { $r in
                    DatePicker(reminderLabel(r), selection: timeBinding($r), displayedComponents: .hourAndMinute)
                        .environment(\.locale, Locale(identifier: "pt_BR"))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                reminders.removeAll { $0.id == r.id }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .accessibilityLabel("Apagar lembrete")
                        }
                }
                if reminders.count < 2 {
                    Button {
                        let hour = reminders.isEmpty ? 8 : 21
                        reminders.append(HabitReminder(hour: hour, minute: 0))
                    } label: {
                        Label("Adicionar lembrete", systemImage: "bell.badge")
                    }
                }
            } header: {
                Text("Lembretes")
            } footer: {
                Text("Até 2 lembretes por hábito. Deslize para apagar.")
            }
            .listRowBackground(Theme.card)
        }
        .font(.inter(16))
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle(existing == nil ? "Novo hábito" : "Editar hábito")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(existing == nil ? "Adicionar" : "Salvar") { save() }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .sheet(isPresented: $showIcons) {
            IconPicker(selected: $icon)
                .presentationDetents([.medium, .large])
        }
        .onAppear(perform: load)
    }

    private var suggestions: [Habit] {
        Library.habits.filter { s in !store.data.habits.contains { $0.title == s.title } }
    }

    private func reminderLabel(_ r: HabitReminder) -> String {
        let i = (reminders.firstIndex { $0.id == r.id } ?? 0) + 1
        return "Lembrete \(i)"
    }

    private func timeBinding(_ r: Binding<HabitReminder>) -> Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: r.wrappedValue.hour, minute: r.wrappedValue.minute, second: 0, of: Date()) ?? Date()
            },
            set: { newValue in
                let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                r.wrappedValue.hour = c.hour ?? 8
                r.wrappedValue.minute = c.minute ?? 0
            }
        )
    }

    private func apply(_ s: Habit) {
        title = s.title
        why = s.why
        avoid = s.avoid
        icon = s.icon
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let h = existing else { return }
        title = h.title
        why = h.why
        avoid = h.avoid
        icon = h.icon
        reminders = h.reminders
    }

    private func save() {
        var h = existing ?? Habit(title: "")
        h.title = title.trimmingCharacters(in: .whitespaces)
        h.why = why.trimmingCharacters(in: .whitespacesAndNewlines)
        h.avoid = avoid
        h.perWeek = 7
        h.icon = icon
        h.reminders = Array(reminders.prefix(2))
        if existing == nil, let onCreate {
            onCreate(h)
            dismiss()
            return
        }
        if existing == nil && !store.canAddHabit {
            dismiss()
            return
        }
        store.saveHabit(h)
        dismiss()
    }
}

/// Grade de ícones para escolher.
struct IconPicker: View {
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 5)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(HabitIcons.all, id: \.self) { name in
                        let on = selected == name
                        Button {
                            selected = name
                            dismiss()
                        } label: {
                            Image(systemName: name)
                                .font(.system(size: 24))
                                .foregroundStyle(on ? Theme.bg : Theme.text)
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .background(Circle().fill(on ? Theme.accent : Theme.card))
                                .overlay(Circle().strokeBorder(on ? Theme.accent : Theme.track, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(name)
                    }
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle("Escolha um ícone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}

/// Conclusão no fim dos 30 dias.
struct ConclusionView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let habit: Habit

    @State private var text = ""
    @State private var decision: HabitDecision = .manter

    var body: some View {
        Form {
            if !habit.why.isEmpty {
                Section("O que você esperava") {
                    Text(habit.why).foregroundStyle(Theme.muted)
                }
                .listRowBackground(Theme.card)
            }
            Section("O que mudou de verdade?") {
                TextField("Escreva com sinceridade", text: $text, axis: .vertical)
                    .lineLimit(4...10)
            }
            .listRowBackground(Theme.card)
            Section("E agora?") {
                ForEach(HabitDecision.allCases) { d in
                    Button {
                        decision = d
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(d.rawValue).foregroundStyle(Theme.text)
                                Text(d.detail).font(.inter(13)).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            if decision == d {
                                Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                            }
                        }
                    }
                }
            }
            .listRowBackground(Theme.card)
        }
        .font(.inter(16))
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Conclusão")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Salvar") {
                    store.saveConclusion(HabitConclusion(text: text.trimmingCharacters(in: .whitespacesAndNewlines), decision: decision), for: habit)
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            if let c = store.conclusion(for: habit) {
                text = c.text
                decision = c.decision
            }
        }
    }
}
