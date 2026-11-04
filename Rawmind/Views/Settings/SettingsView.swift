import SwiftUI

/// Ajustes: mudar rotina, horário, hábitos, alternativas e recomeçar.
struct SettingsView: View {
    @Environment(Store.self) private var store
    @State private var confirmReset = false
    @State private var confirmQuit = false

    var body: some View {
        NavigationStack {
            List {
                Section("Rotina matinal") {
                    NavigationLink {
                        RoutineEditor()
                    } label: {
                        row("Itens da rotina", "\(store.data.routine.count)")
                    }
                    DatePicker("Horário", selection: timeBinding, displayedComponents: .hourAndMinute)
                        .environment(\.locale, Locale(identifier: "pt_BR"))
                }
                .listRowBackground(Theme.card)

                Section("Seu dia") {
                    NavigationLink {
                        AlternativesEditor()
                    } label: {
                        row("Em vez de abrir, eu vou…", "\(store.data.alternatives.count)")
                    }
                }
                .listRowBackground(Theme.card)

                if let run = store.data.monk {
                    Section {
                        row("Monk Mode começou", PTDate.short(run.startDate))
                        if store.monkActive {
                            Button("Encerrar Monk Mode", role: .destructive) { confirmQuit = true }
                        }
                    } header: {
                        Text("Monk Mode")
                    } footer: {
                        Text("Encerrar conta como uma tentativa. Você pode começar outro quando quiser.")
                    }
                    .listRowBackground(Theme.card)
                }

                Section {
                    if let start = store.data.startDate {
                        row("Rotina desde", PTDate.short(start))
                    }
                    Button("Recomeçar do zero", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("Recomeçar apaga sua rotina, hábitos e histórico deste celular.")
                }
                .listRowBackground(Theme.card)
            }
            .font(.inter(16))
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("Ajustes")
            .confirmationDialog("Encerrar o Monk Mode?", isPresented: $confirmQuit, titleVisibility: .visible) {
                Button("Encerrar", role: .destructive) { store.quitMonk() }
                Button("Continuar no Monk Mode", role: .cancel) {}
            } message: {
                Text("Você volta pro começo. Seu histórico de hábitos fica guardado.")
            }
            .confirmationDialog("Recomeçar do zero?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Apagar e recomeçar", role: .destructive) { store.reset() }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Isso apaga tudo o que está salvo e volta para o começo.")
            }
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(Theme.muted)
        }
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: store.data.routineHour, minute: store.data.routineMinute, second: 0, of: Date()) ?? Date()
            },
            set: { newValue in
                let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                let h = c.hour ?? 7
                let m = c.minute ?? 0
                store.update { d in
                    d.routineHour = h
                    d.routineMinute = m
                }
                Notifications.scheduleMorning(hour: h, minute: m)
            }
        )
    }
}
