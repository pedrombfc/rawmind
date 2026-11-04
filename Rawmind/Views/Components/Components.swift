import SwiftUI

/// Botão principal âmbar.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.archivo(18, bold: true))
            .foregroundStyle(Theme.bg)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Theme.accent.opacity(isEnabled ? 1 : 0.35))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

/// Caixinha de marcar (feito / não feito).
struct CheckBox: View {
    let done: Bool
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            if done {
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .fill(Theme.done)
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(Theme.bg)
            } else {
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 2)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Barra de progresso fina.
struct ThinBar: View {
    let value: Double
    var height: CGFloat = 6
    var color: Color = Theme.accent

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.track)
                Capsule().fill(color)
                    .frame(width: geo.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: height)
    }
}

/// Barrinhas de passos (onboarding e rotina).
struct StepBars: View {
    let total: Int
    let filled: Int
    var color: Color = Theme.accent
    var height: CGFloat = 4

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<max(total, 1), id: \.self) { i in
                Capsule()
                    .fill(i < filled ? color : Theme.track)
                    .frame(height: height)
            }
        }
    }
}

/// Título pequeno em maiúsculas.
struct SectionLabel: View {
    let text: String
    var color: Color = Theme.muted

    var body: some View {
        Text(text.uppercased())
            .font(.inter(13, .semibold))
            .tracking(1.3)
            .foregroundStyle(color)
    }
}

/// Pílula selecionável.
struct Chip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.inter(15, selected ? .semibold : .regular))
                .foregroundStyle(selected ? Theme.bg : Theme.text)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(
                    Capsule().fill(selected ? Theme.accent : Color.clear)
                )
                .overlay(
                    Capsule().strokeBorder(selected ? Theme.accent : Theme.chipBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

/// Layout que quebra linha automaticamente (para as pílulas).
struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

extension View {
    /// Fundo escuro padrão de tela.
    func screenBackground() -> some View {
        self.background(Theme.bg.ignoresSafeArea())
    }

    /// Cartão escuro arredondado.
    func card(padding: CGFloat = 16, radius: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}
