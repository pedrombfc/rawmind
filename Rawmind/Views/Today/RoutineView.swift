import SwiftUI
import UIKit

/// Rotina matinal: marcar cada item.
struct RoutineView: View {
    @Environment(Store.self) private var store
    @State private var editing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel(text: "Obrigatória · sua escolha de itens", color: Theme.accent)
                    Text("Rotina matinal")
                        .font(.archivo(34))
                        .tracking(-0.6)
                    Text("\(store.routineDoneCount) de \(store.data.routine.count) feitos")
                        .font(.inter(15))
                        .foregroundStyle(Theme.muted)
                }

                VStack(spacing: 8) {
                    ForEach(store.data.routine) { item in
                        let done = store.isRoutineItemDone(item)
                        Button {
                            withAnimation(.snappy) { store.toggleRoutineItem(item) }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            HStack(spacing: 14) {
                                CheckBox(done: done)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.inter(16, .medium))
                                        .foregroundStyle(done ? Theme.muted : Theme.text)
                                        .strikethrough(done, color: Theme.muted)
                                    if !item.why.isEmpty {
                                        Text(item.why)
                                            .font(.inter(13))
                                            .foregroundStyle(Theme.muted)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .card(padding: 14)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(done ? .isSelected : [])
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(coachLine)
                        .font(.archivo(17, bold: true))
                    Text(store.routineComplete
                         ? "Feita antes da tela. Isso conta como dia completo."
                         : "Quando terminar tudo, o dia de hoje conta no seu protocolo.")
                        .font(.inter(14))
                        .foregroundStyle(Theme.muted)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Theme.track, lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .screenBackground()
        .foregroundStyle(Theme.text)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar rotina") { editing = true }
                    .font(.inter(15))
                    .foregroundStyle(Theme.muted)
            }
        }
        .sheet(isPresented: $editing) {
            NavigationStack { RoutineEditor() }
        }
    }

    private var coachLine: String {
        let left = store.data.routine.count - store.routineDoneCount
        if left <= 0 { return "Rotina feita. O dia é seu." }
        if left == 1 { return "Falta 1. Termina isso." }
        return "Faltam \(left). Bora terminar."
    }
}
