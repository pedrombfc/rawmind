import SwiftUI
import UIKit

/// "Ler": registrar quantas páginas você leu (e de qual livro).
struct ReadLogView: View {
    @Environment(Store.self) private var store
    let onDone: () -> Void

    @State private var pages = 10
    @State private var book = ""
    @State private var finished = false
    @State private var loaded = false
    @FocusState private var bookFocused: Bool

    private let quick = [5, 10, 20, 50]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionLabel(text: "Ler", color: Theme.accent)
                Text("Quantas páginas você leu?")
                    .font(.archivo(32))
                    .tracking(-0.5)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 28) {
                    stepButton("minus") { pages = max(pages - 1, 1) }
                        .accessibilityLabel("Menos uma página")
                    VStack(spacing: 2) {
                        Text("\(pages)")
                            .font(.archivo(72))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text(pages == 1 ? "página" : "páginas")
                            .font(.inter(14))
                            .foregroundStyle(Theme.muted)
                    }
                    .frame(minWidth: 120)
                    stepButton("plus") { pages = min(pages + 1, 999) }
                        .accessibilityLabel("Mais uma página")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)

                HStack(spacing: 10) {
                    ForEach(quick, id: \.self) { n in
                        Chip(label: "\(n)", selected: pages == n) {
                            withAnimation(.snappy) { pages = n }
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Text("Livro").foregroundStyle(Theme.muted)
                        TextField("", text: $book, prompt: Text("Qual livro? (opcional)").foregroundStyle(Theme.muted))
                            .multilineTextAlignment(.trailing)
                            .focused($bookFocused)
                            .submitLabel(.done)
                    }
                    .padding(.vertical, 15)
                    Divider().overlay(Theme.track)
                    Toggle("Terminei esse livro", isOn: $finished)
                        .tint(Theme.done)
                        .padding(.vertical, 10)
                }
                .font(.inter(16))
                .padding(.horizontal, 18)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Text("No fim do mês você vê quantas páginas e quantos livros leu.")
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            Button("Registrar leitura", action: save)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .background(Theme.bg)
        }
        .foregroundStyle(Theme.text)
        .screenBackground()
        .navigationTitle("Ler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            guard !loaded else { return }
            loaded = true
            book = store.lastBook
        }
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy) { action() }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Theme.text)
                .frame(width: 56, height: 56)
                .overlay(Circle().strokeBorder(Theme.chipBorder, lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func save() {
        let title = book.trimmingCharacters(in: .whitespacesAndNewlines)
        store.logMind(MindSession(kind: .ler, title: title, pages: pages, finishedBook: finished))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onDone()
    }
}
