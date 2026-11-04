import SwiftUI

/// Texto com **negrito** (markdown simples).
func markdown(_ s: String) -> AttributedString {
    (try? AttributedString(markdown: s)) ?? AttributedString(s)
}

/// Selo de evidência (Forte / Moderada / Inicial).
struct EvidencePill: View {
    let evidence: Evidence
    var long = false
    var size: CGFloat = 13

    var body: some View {
        Text(long ? evidence.long : evidence.label)
            .font(.inter(size, .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(background))
            .lineLimit(1)
    }

    private var color: Color {
        switch evidence {
        case .forte: return Theme.done
        case .moderada: return Theme.accent
        case .inicial: return Theme.muted
        }
    }

    private var background: Color {
        switch evidence {
        case .forte: return Theme.doneBg
        case .moderada: return Theme.accent.opacity(0.14)
        case .inicial: return Theme.track
        }
    }
}

/// Pílula neutra (duração, quando, categoria).
struct InfoPill: View {
    let text: String
    var size: CGFloat = 13

    var body: some View {
        Text(text)
            .font(.inter(size, .medium))
            .foregroundStyle(Theme.muted)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(Theme.track))
            .lineLimit(1)
    }
}

/// Aba Guias: os hábitos explicados, com busca e categorias.
struct GuidesView: View {
    @State private var query = ""
    @State private var category: ActivityCategory? = nil
    @FocusState private var searching: Bool

    private var isFiltering: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty || category != nil }

    private func guides(in cat: ActivityCategory) -> [Guide] {
        let q = query.trimmingCharacters(in: .whitespaces)
        return Guide.all.filter { g in
            g.category == cat && (q.isEmpty
                || g.title.localizedStandardContains(q)
                || g.summary.localizedStandardContains(q))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Guias")
                            .font(.archivo(34))
                            .tracking(-0.6)
                        Text("\(Guide.all.count) hábitos explicados: como fazer e por que funciona.")
                            .font(.inter(16))
                            .foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    searchField

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            Chip(label: "Todos", selected: category == nil) {
                                withAnimation(.snappy) { category = nil }
                            }
                            ForEach(ActivityCategory.allCases) { cat in
                                Chip(label: cat.title, selected: category == cat) {
                                    withAnimation(.snappy) { category = category == cat ? nil : cat }
                                }
                            }
                        }
                    }
                    .safeAreaPadding(.horizontal, 20)
                    .padding(.horizontal, -20)

                    if !isFiltering {
                        featuredCard
                    }

                    let cats = (category.map { [$0] } ?? ActivityCategory.allCases)
                        .filter { !guides(in: $0).isEmpty }
                    if cats.isEmpty {
                        Text("Nenhum guia com esse nome.")
                            .font(.inter(16))
                            .foregroundStyle(Theme.muted)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    } else {
                        ForEach(cats) { cat in
                            section(cat, guides(in: cat))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
            .foregroundStyle(Theme.text)
            .screenBackground()
            .statusBarCover()
            .navigationTitle("Guias")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Guide.self) { guide in
                GuideDetailView(guide: guide)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.muted)
            TextField("", text: $query, prompt: Text("Buscar guia").foregroundStyle(Theme.muted))
                .font(.inter(17))
                .focused($searching)
                .submitLabel(.search)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.muted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Limpar busca")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.card))
    }

    private var featuredCard: some View {
        let g = Guide.featured
        return NavigationLink(value: g) {
            VStack(alignment: .leading, spacing: 16) {
                SectionLabel(text: "Comece por aqui", color: Theme.accent)
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: g.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 54, height: 54)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.bg))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(g.title)
                            .font(.archivo(21, bold: true))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(g.summary)
                            .font(.inter(15))
                            .foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                HStack(spacing: 8) {
                    EvidencePill(evidence: g.evidence)
                    InfoPill(text: g.duration)
                    InfoPill(text: g.category.title)
                }
            }
            .foregroundStyle(Theme.text)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [Color(hex: 0x2A2419), Theme.card],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func section(_ cat: ActivityCategory, _ items: [Guide]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(cat.title)
                    .font(.archivo(22, bold: true))
                Spacer()
                Text(items.count == 1 ? "1 guia" : "\(items.count) guias")
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
            }
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, guide in
                    if index > 0 {
                        Divider().overlay(Theme.track)
                    }
                    NavigationLink(value: guide) {
                        row(guide)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private func row(_ g: Guide) -> some View {
        HStack(spacing: 14) {
            Image(systemName: g.icon)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(Theme.accent)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.track))
            VStack(alignment: .leading, spacing: 2) {
                Text(g.title)
                    .font(.inter(16, .semibold))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(g.duration)
                    .font(.inter(14))
                    .foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 8)
            EvidencePill(evidence: g.evidence, size: 12)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.muted)
        }
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

/// Um guia completo: como fazer, por que funciona, o que a ciência diz e cuidados.
struct GuideDetailView: View {
    let guide: Guide

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SectionLabel(text: guide.category.title)
                HStack(spacing: 14) {
                    Image(systemName: guide.icon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 60, height: 60)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.card))
                    Text(guide.title)
                        .font(.archivo(32))
                        .tracking(-0.6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 10)

                Text(guide.summary)
                    .font(.inter(17))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)

                FlowLayout(spacing: 8) {
                    EvidencePill(evidence: guide.evidence, long: true)
                    InfoPill(text: guide.duration)
                    InfoPill(text: guide.when)
                }
                .padding(.top, 14)

                heading("Como fazer")
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(guide.steps.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: 14) {
                            Text("\(i + 1)")
                                .font(.inter(15, .semibold))
                                .foregroundStyle(Theme.bg)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Theme.accent))
                            Text(markdown(step))
                                .font(.inter(17))
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 2)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                heading("Por que funciona")
                Text(guide.why)
                    .font(.inter(17))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                heading("O que a ciência diz")
                HStack(alignment: .top, spacing: 14) {
                    EvidencePill(evidence: guide.evidence, size: 12)
                    Text(markdown(guide.science))
                        .font(.inter(16))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                if let care = guide.care {
                    heading("Cuidados")
                    Text(care)
                        .font(.inter(17))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 32)
        }
        .foregroundStyle(Theme.text)
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func heading(_ text: String) -> some View {
        Text(text)
            .font(.archivo(22, bold: true))
            .padding(.top, 30)
            .padding(.bottom, 12)
    }
}
