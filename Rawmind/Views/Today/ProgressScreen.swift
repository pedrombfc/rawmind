import SwiftUI

/// Progresso: estatísticas em cima (tempo de tela, trocas, caderno) e, embaixo,
/// as atividades para fazer no lugar do celular.
struct ProgressScreen: View {
    @Environment(Store.self) private var store
    @State private var path: [MindKind] = []
    @State private var showOther = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Progresso")
                        .font(.archivo(34))
                        .tracking(-0.6)
                        .padding(.bottom, 4)

                    ScreenTimeCard()

                    mindCard

                    let week = store.mindLastWeek
                    HStack(spacing: 10) {
                        tile("\(store.mindMinutes(.pensar, in: week))", "min pensando")
                        tile("\(store.mindMinutes(.ler, in: week))", "min lendo")
                        tile("\(week.reduce(0) { $0 + $1.wordCount })", "palavras escritas")
                    }

                    NavigationLink {
                        JournalView()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "pencil.line")
                                .font(.system(size: 20, weight: .medium))
                                .frame(width: 48, height: 48)
                                .background(Circle().fill(Theme.track))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Seu caderno").font(.inter(16, .semibold))
                                Text(store.journal.count == 1 ? "1 texto" : "\(store.journal.count) textos")
                                    .font(.inter(14))
                                    .foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
                        }
                        .foregroundStyle(Theme.text)
                        .card(padding: 14, radius: 20)
                    }
                    .buttonStyle(.plain)

                    activities
                        .padding(.top, 10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .foregroundStyle(Theme.text)
            .screenBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: MindKind.self) { kind in
                if kind == .escrever {
                    WriteView(onDone: { path.removeAll() })
                } else {
                    MindExerciseView(kind: kind, onDone: { path.removeAll() })
                }
            }
        }
        .sheet(isPresented: $showOther) {
            NavigationStack { OtherSwapView() }
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: Sua mente

    private var mindCard: some View {
        let counts = store.mindDailyCounts
        let total = counts.reduce(0) { $0 + $1.count }
        return VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Sua mente · últimos 7 dias", color: Theme.accent)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(total)").font(.archivo(44))
                Text(total == 1 ? "troca em vez do celular" : "trocas em vez do celular")
                    .font(.inter(15))
                    .foregroundStyle(Theme.muted)
            }
            WeekBars(counts: counts)
        }
        .card(padding: 18, radius: 20)
    }

    // MARK: Em vez do celular

    private static let activityKinds: [MindKind] = [.ler, .escrever, .pensar, .respirar, .meditar, .outro]

    private var activities: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Em vez do celular", color: Theme.accent)
            Text("Toque numa atividade pra começar. Fica registrado como uma troca.")
                .font(.inter(14))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 2)
            let kinds = ProgressScreen.activityKinds
            ForEach(0..<(kinds.count / 2), id: \.self) { row in
                HStack(spacing: 10) {
                    activityCard(kinds[row * 2])
                    activityCard(kinds[row * 2 + 1])
                }
            }
        }
    }

    private func activityCard(_ kind: MindKind) -> some View {
        let today = store.mindSessions(on: Date()).filter { $0.kind == kind }.count
        return Button {
            if kind == .outro {
                showOther = true
            } else {
                path.append(kind)
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Image(systemName: kind.icon)
                        .font(.system(size: 19, weight: .medium))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Theme.track))
                    Spacer(minLength: 4)
                    if today > 0 {
                        Text("\(today)x hoje")
                            .font(.inter(13, .semibold))
                            .foregroundStyle(Theme.done)
                    }
                }
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind == .pensar ? "Pensar" : kind.title)
                        .font(.inter(16, .semibold))
                    Text(activitySubtitle(kind))
                        .font(.inter(13))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            .foregroundStyle(Theme.text)
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func activitySubtitle(_ kind: MindKind) -> String {
        switch kind {
        case .outro: return "Registrar o que fez"
        case .pensar: return "\(kind.defaultMinutes) min, sem tela"
        default: return "\(kind.defaultMinutes) min"
        }
    }

    private func tile(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.archivo(22, bold: true))
            Text(label)
                .font(.inter(12))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.track, lineWidth: 1)
        )
    }
}

/// Barras das trocas de cada dia (hoje em âmbar).
private struct WeekBars: View {
    let counts: [DayCount]

    var body: some View {
        let maxValue = max(counts.map(\.count).max() ?? 0, 1)
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(counts.enumerated()), id: \.offset) { index, day in
                let isToday = index == counts.count - 1
                VStack(spacing: 6) {
                    Text("\(day.count)")
                        .font(.inter(12))
                        .foregroundStyle(Theme.muted)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isToday ? Theme.accent : (day.count == 0 ? Theme.track : Theme.done))
                        .frame(height: CGFloat(day.count) / CGFloat(maxValue) * 90 + 4)
                    Text(isToday ? "HOJE" : weekday(day.date))
                        .font(.inter(11, .semibold))
                        .foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 140, alignment: .bottom)
    }

    private func weekday(_ date: Date) -> String {
        let names = ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SÁB"]
        return names[(Calendar.current.component(.weekday, from: date) - 1) % 7]
    }
}

