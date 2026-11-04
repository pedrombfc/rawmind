import SwiftUI

/// Criar ou editar um hábito do Monk Mode.
struct HabitFormView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let existing: Habit?

    @State private var title = ""
    @State private var why = ""
    @State private var avoid = false
    @State private var perWeek = 7
    @State private var period: DayPeriod = .qualquer
    @State private var reminderOn = false
    @State private var reminderTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var loaded = false

    var body: some View {
        Form {
            if existing == nil {
                Section("Sugestões") {
                    FlowLayout(spacing: 8) {
                        ForEach(suggestions) { s in
                            Chip(label: s.title, selected: title == s.title) { apply(s) }
                        }
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Theme.card)
            }

            Section {
                Picker("Tipo", selection: $avoid) {
                    Text("Fazer").tag(false)
                    Text("Evitar").tag(true)
                }
                .pickerStyle(.segmented)
                TextField(avoid ? "Ex.: Sem redes antes do meio-dia" : "Ex.: Ler 10 páginas", text: $title)
            } header: {
                Text("Nome")
            } footer: {
                Text(avoid
                     ? "Hábitos de evitar você confirma à noite: \"hoje eu me mantive\"."
                     : "Algo pequeno e claro, que dá pra marcar como feito.")
            }
            .listRowBackground(Theme.card)

            Section {
                TextField("Ex.: Dormir melhor e ter mais energia", text: $why, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text("O que você espera que mude?")
            } footer: {
                Text("No dia 30 você volta aqui e compara.")
            }
            .listRowBackground(Theme.card)

            Section("Detalhes") {
                if !avoid {
                    Picker("Frequência", selection: $perWeek) {
                        Text("Todo dia").tag(7)
                        ForEach([6, 5, 4, 3, 2], id: \.self) { n in
                            Text("\(n)x por semana").tag(n)
                        }
                    }
                }
                Picker("Quando", selection: $period) {
                    ForEach(DayPeriod.allCases) { p in Text(p.rawValue).tag(p) }
                }
                HStack {
                    Text("Duração")
                    Spacer()
                    Text("30 dias · Monk Mode").foregroundStyle(Theme.muted)
                }
                Toggle("Lembrete", isOn: $reminderOn)
                if reminderOn {
                    DatePicker("Horário", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .environment(\.locale, Locale(identifier: "pt_BR"))
                }
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
        .onAppear(perform: load)
    }

    private var suggestions: [Habit] {
        Library.habits.filter { s in !store.data.habits.contains { $0.title == s.title } }
    }

    private func apply(_ s: Habit) {
        title = s.title
        why = s.why
        avoid = s.avoid
        period = s.period
        perWeek = s.perWeek
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let h = existing else { return }
        title = h.title
        why = h.why
        avoid = h.avoid
        perWeek = h.perWeek
        period = h.period
        reminderOn = h.reminderOn
        reminderTime = Calendar.current.date(bySettingHour: h.reminderHour, minute: h.reminderMinute, second: 0, of: Date()) ?? Date()
    }

    private func save() {
        var h = existing ?? Habit(title: "", period: period)
        h.title = title.trimmingCharacters(in: .whitespaces)
        h.why = why.trimmingCharacters(in: .whitespacesAndNewlines)
        h.avoid = avoid
        h.perWeek = avoid ? 7 : perWeek
        h.period = period
        h.reminderOn = reminderOn
        let c = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        h.reminderHour = c.hour ?? 18
        h.reminderMinute = c.minute ?? 0
        if existing == nil && !store.canAddHabit {
            dismiss()
            return
        }
        store.saveHabit(h)
        dismiss()
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
