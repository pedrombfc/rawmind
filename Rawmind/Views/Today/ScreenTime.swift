import SwiftUI

/// Cartão "Tempo de tela · antes x agora".
struct ScreenTimeCard: View {
    @Environment(Store.self) private var store
    @State private var form: ScreenFormMode? = nil

    enum ScreenFormMode: Int, Identifiable {
        case baseline, week
        var id: Int { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Tempo de tela · antes x agora", color: Theme.accent)
            if let base = store.data.screenBaseline {
                if let now = store.latestScreen {
                    Text("Média por dia: antes do Rawmind x semana anotada em \(PTDate.short(now.date))")
                        .font(.inter(13))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    CompareRow(title: "Celular no total", before: base.totalMinutes, now: now.totalMinutes, isCount: false)
                    CompareRow(title: "Instagram", before: base.instagramMinutes, now: now.instagramMinutes, isCount: false)
                    if base.pickups > 0 && now.pickups > 0 {
                        CompareRow(title: "Vezes que pegou o celular", before: base.pickups, now: now.pickups, isCount: true)
                    }
                    yearCompare(before: base.totalMinutes, now: now.totalMinutes)
                    savedBanner(before: base.totalMinutes, now: now.totalMinutes)
                } else {
                    Text("Antes do Rawmind: \(Store.durationText(base.totalMinutes)) por dia, \(Store.durationText(base.instagramMinutes)) de Instagram.")
                        .font(.inter(15))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Isso dá \(Store.daysPerYear(base.totalMinutes)) dias por ano no celular. Daqui a uma semana, anote de novo para ver a diferença.")
                        .font(.inter(14))
                        .foregroundStyle(Theme.muted)
                }
                if store.needsScreenUpdate {
                    Button("Anotar esta semana") { form = .week }
                        .buttonStyle(PrimaryButtonStyle())
                } else {
                    Button("Anotar de novo") { form = .week }
                        .font(.inter(15, .semibold))
                        .foregroundStyle(Theme.accent)
                }
            } else {
                Text("Quanto do seu dia vai pro celular?")
                    .font(.archivo(19, bold: true))
                Text("Anote seu tempo de tela de agora. Depois a gente compara, semana a semana.")
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Anotar meu ponto de partida") { form = .baseline }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .card(padding: 18, radius: 20)
        .sheet(item: $form) { mode in
            NavigationStack { ScreenTimeForm(isBaseline: mode == .baseline) }
                .trackedModal()
        }
    }

    /// Dias por ano no celular: antes x no ritmo de agora.
    private func yearCompare(before: Int, now: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider().overlay(Theme.track)
            SectionLabel(text: "Dias por ano no celular")
                .padding(.top, 4)
            HStack(alignment: .bottom, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Store.daysPerYear(before))")
                        .font(.archivo(28))
                        .foregroundStyle(Theme.muted)
                        .strikethrough(true, color: Theme.muted)
                    Text("antes").font(.inter(13)).foregroundStyle(Theme.muted)
                }
                Image(systemName: "arrow.right")
                    .foregroundStyle(Theme.muted)
                    .padding(.bottom, 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Store.daysPerYear(now))")
                        .font(.archivo(42))
                        .foregroundStyle(now <= before ? Theme.done : Theme.accent)
                    Text("no ritmo de agora").font(.inter(13)).foregroundStyle(Theme.muted)
                }
            }
        }
    }

    @ViewBuilder
    private func savedBanner(before: Int, now: Int) -> some View {
        let perDay = before - now
        let daysBack = Store.daysPerYear(before) - Store.daysPerYear(now)
        if perDay > 0 {
            let perWeek = perDay * 7
            VStack(alignment: .leading, spacing: 4) {
                Text(daysBack >= 2 ? "\(daysBack) dias por ano de volta" : (daysBack == 1 ? "1 dia por ano de volta" : "\(Store.durationText(perWeek)) livres por semana"))
                    .font(.archivo(18, bold: true))
                    .foregroundStyle(Theme.done)
                Text(daysBack >= 1 ? "São \(Store.durationText(perWeek)) livres por semana." : "Cada minuto conta.")
                    .font(.inter(14))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.doneBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            Text("Ainda não caiu. Normal no começo: o que conta é a tendência.")
                .font(.inter(14))
                .foregroundStyle(Theme.muted)
        }
    }
}

private struct CompareRow: View {
    let title: String
    let before: Int
    let now: Int
    let isCount: Bool

    var body: some View {
        let better = now <= before
        let pct = before > 0 ? Int((Double(now - before) / Double(before) * 100).rounded()) : 0
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title).font(.inter(15, .semibold))
                Spacer(minLength: 4)
                Text(format(before))
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
                    .strikethrough(true, color: Theme.muted)
                Text(format(now))
                    .font(.archivo(20, bold: true))
            }
            HStack(spacing: 8) {
                ThinBar(value: before > 0 ? Double(now) / Double(before) : 0, height: 8, color: better ? Theme.done : Theme.accent)
                Text(pct > 0 ? "+\(pct)%" : "\(pct)%")
                    .font(.inter(13, .semibold))
                    .foregroundStyle(better ? Theme.done : Theme.accent)
                    .frame(width: 52, alignment: .trailing)
            }
        }
    }

    private func format(_ v: Int) -> String {
        isCount ? "\(v)" : Store.durationText(v)
    }
}

/// Anotar o tempo de tela (média por dia, tirada de Ajustes > Tempo de Uso).
struct ScreenTimeForm: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let isBaseline: Bool

    @State private var totalH = 4
    @State private var totalM = 0
    @State private var igH = 1
    @State private var igM = 0
    @State private var pickups = ""
    @State private var loaded = false

    var body: some View {
        Form {
            Section {
                Text("No iPhone, abra Ajustes > Tempo de Uso > Ver toda a atividade e escolha Semana. Use a média por dia.")
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
            }
            .listRowBackground(Theme.card)

            Section("Celular no total, por dia") {
                DurationPicker(hours: $totalH, minutes: $totalM)
            }
            .listRowBackground(Theme.card)

            Section("Instagram (ou a rede que mais te prende)") {
                DurationPicker(hours: $igH, minutes: $igM)
            }
            .listRowBackground(Theme.card)

            Section {
                TextField("Ex.: 80", text: $pickups)
                    .keyboardType(.numberPad)
            } header: {
                Text("Vezes que pegou o celular por dia")
            } footer: {
                Text("Opcional. Aparece mais embaixo na mesma tela do Tempo de Uso.")
            }
            .listRowBackground(Theme.card)
        }
        .font(.inter(16))
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle(isBaseline ? "Ponto de partida" : "Tempo de tela da semana")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Salvar") { save() }.fontWeight(.semibold)
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let e = store.latestScreen ?? store.data.screenBaseline else { return }
        totalH = min(e.totalMinutes / 60, 16)
        totalM = (e.totalMinutes % 60) / 5 * 5
        igH = min(e.instagramMinutes / 60, 16)
        igM = (e.instagramMinutes % 60) / 5 * 5
    }

    private func save() {
        let entry = ScreenTimeEntry(
            totalMinutes: totalH * 60 + totalM,
            instagramMinutes: igH * 60 + igM,
            pickups: Int(pickups.trimmingCharacters(in: .whitespaces)) ?? 0
        )
        if isBaseline {
            store.saveBaseline(entry)
        } else {
            store.addScreenEntry(entry)
        }
        dismiss()
    }
}

/// Dois rolinhos: horas e minutos.
struct DurationPicker: View {
    @Binding var hours: Int
    @Binding var minutes: Int

    var body: some View {
        HStack(spacing: 0) {
            Picker("Horas", selection: $hours) {
                ForEach(0..<17, id: \.self) { h in Text("\(h) h").tag(h) }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .clipped()
            Picker("Minutos", selection: $minutes) {
                ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { m in Text("\(m) min").tag(m) }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .clipped()
        }
    }
}
