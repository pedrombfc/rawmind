import SwiftUI

/// Editar os itens da rotina matinal.
struct RoutineEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var newTitle = ""

    var body: some View {
        List {
            Section {
                ForEach(store.data.routine) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                        if !item.why.isEmpty {
                            Text(item.why).font(.inter(13)).foregroundStyle(Theme.muted)
                        }
                    }
                    .deleteDisabled(store.data.routine.count <= 1)
                }
                .onDelete { offsets in
                    store.update { $0.routine.remove(atOffsets: offsets) }
                    store.refreshTodayCompletion()
                }
                .onMove { from, to in
                    store.update { $0.routine.move(fromOffsets: from, toOffset: to) }
                }
            } header: {
                Text("Sua rotina")
            } footer: {
                Text("Arraste para mudar a ordem. Deslize para a esquerda para tirar um item.")
            }
            .listRowBackground(Theme.card)

            let suggestions = Library.routine.filter { s in !store.data.routine.contains { $0.title == s.title } }
            if !suggestions.isEmpty {
                Section("Sugestões") {
                    ForEach(suggestions) { s in
                        Button {
                            add(RoutineItem(title: s.title, why: s.why))
                        } label: {
                            Label(s.title, systemImage: "plus.circle")
                        }
                    }
                }
                .listRowBackground(Theme.card)
            }

            Section("Criar o seu") {
                HStack {
                    TextField("Ex.: Escrever 3 linhas", text: $newTitle)
                        .submitLabel(.done)
                        .onSubmit(addCustom)
                    Button("Adicionar", action: addCustom)
                        .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .listRowBackground(Theme.card)
        }
        .font(.inter(16))
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Editar rotina")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { EditButton() }
            ToolbarItem(placement: .topBarTrailing) {
                Button("OK") { dismiss() }
                    .fontWeight(.semibold)
            }
        }
    }

    private func add(_ item: RoutineItem) {
        store.update { $0.routine.append(item) }
        store.refreshTodayCompletion()
    }

    private func addCustom() {
        let t = newTitle.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        add(RoutineItem(title: t, why: ""))
        newTitle = ""
    }
}

/// Escolher até 3 coisas para fazer em vez de abrir o Instagram.
struct AlternativesEditor: View {
    @Environment(Store.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Escolha até 3. Quando o escudo chegar, é isso que o app vai te sugerir no lugar do scroll.")
                    .font(.inter(15))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                FlowLayout(spacing: 10) {
                    ForEach(Library.alternatives, id: \.self) { option in
                        let on = store.data.alternatives.contains(option)
                        Chip(label: option.prefix(1).uppercased() + option.dropFirst(), selected: on) {
                            store.update { d in
                                if let i = d.alternatives.firstIndex(of: option) {
                                    d.alternatives.remove(at: i)
                                } else {
                                    d.alternatives = Array((d.alternatives + [option]).suffix(3))
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .foregroundStyle(Theme.text)
        .screenBackground()
        .navigationTitle("Em vez de abrir")
        .navigationBarTitleDisplayMode(.inline)
    }
}
