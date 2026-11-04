import SwiftUI

/// Polígono desenhado numa grade de 100 x 110 (o formato da medalha).
struct DesignPolygon: Shape {
    let points: [CGPoint]
    var closed = true

    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 100
        let sy = rect.height / 110
        let mapped = points.map { CGPoint(x: rect.minX + $0.x * sx, y: rect.minY + $0.y * sy) }
        var p = Path()
        guard let first = mapped.first else { return p }
        p.move(to: first)
        for pt in mapped.dropFirst() { p.addLine(to: pt) }
        if closed { p.closeSubpath() }
        return p
    }

    static let outer = DesignPolygon(points: [
        CGPoint(x: 50, y: 5), CGPoint(x: 91, y: 28.5), CGPoint(x: 91, y: 81.5),
        CGPoint(x: 50, y: 105), CGPoint(x: 9, y: 81.5), CGPoint(x: 9, y: 28.5),
    ])
    static let inner = DesignPolygon(points: [
        CGPoint(x: 50, y: 15), CGPoint(x: 82, y: 33.5), CGPoint(x: 82, y: 76.5),
        CGPoint(x: 50, y: 95), CGPoint(x: 18, y: 76.5), CGPoint(x: 18, y: 33.5),
    ])
    static let shine = DesignPolygon(points: [
        CGPoint(x: 18, y: 33.5), CGPoint(x: 50, y: 15), CGPoint(x: 82, y: 33.5),
    ], closed: false)
}

/// Cores de cada nível de medalha.
private struct MedalColors {
    let light: Color
    let dark: Color
    let core: Color
    let shine: Color

    static func of(_ tier: AchievementTier) -> MedalColors {
        switch tier {
        case .bronze: return MedalColors(light: Color(hex: 0xD39363), dark: Color(hex: 0x8C5530), core: Color(hex: 0x5A3519), shine: Color(hex: 0xFFE2C9))
        case .prata: return MedalColors(light: Color(hex: 0xE4E6EA), dark: Color(hex: 0x9CA1A9), core: Color(hex: 0x5E636B), shine: Color(hex: 0xFFFFFF))
        case .ouro: return MedalColors(light: Color(hex: 0xFFD27A), dark: Color(hex: 0xE09422), core: Color(hex: 0x8A560B), shine: Color(hex: 0xFFF3D6))
        case .lenda: return MedalColors(light: Color(hex: 0xA9E3CF), dark: Color(hex: 0x4E9C83), core: Color(hex: 0x22584A), shine: Color(hex: 0xE9FFF7))
        }
    }
}

/// A medalha de uma conquista: hexágono com ícone e número. Cinza quando ainda não foi ganha.
struct MedalView: View {
    let achievement: Achievement
    var size: CGFloat = 84
    var locked = false
    /// Mostra "×3" no canto (nas que renovam).
    var times: Int? = nil

    var body: some View {
        let c = MedalColors.of(achievement.tier)
        let ring = LinearGradient(colors: [c.light, c.dark], startPoint: .topLeading, endPoint: .bottomTrailing)
        let iconColor = locked ? Color(hex: 0x55534D) : c.shine
        let textColor = locked ? Color(hex: 0x6B6962) : c.shine
        let hasBadge = achievement.badge != nil

        ZStack {
            if locked {
                DesignPolygon.outer.fill(Theme.card)
                DesignPolygon.outer.stroke(Color(hex: 0x2E2D29), style: StrokeStyle(lineWidth: size * 0.05, lineJoin: .round))
                DesignPolygon.inner.fill(Color(hex: 0x141310))
                DesignPolygon.inner.stroke(Color(hex: 0x262521), style: StrokeStyle(lineWidth: max(size * 0.02, 1), lineJoin: .round))
            } else {
                DesignPolygon.outer.fill(ring)
                DesignPolygon.outer.stroke(ring, style: StrokeStyle(lineWidth: size * 0.06, lineJoin: .round))
                DesignPolygon.inner.fill(LinearGradient(colors: [c.core, c.core.opacity(0.78)], startPoint: .top, endPoint: .bottom))
                DesignPolygon.inner.stroke(c.shine.opacity(0.35), style: StrokeStyle(lineWidth: max(size * 0.015, 0.75), lineJoin: .round))
                DesignPolygon.shine.stroke(c.shine.opacity(0.5), style: StrokeStyle(lineWidth: max(size * 0.02, 1), lineCap: .round, lineJoin: .round))
            }

            VStack(spacing: size * 0.02) {
                Image(systemName: achievement.icon)
                    .font(.system(size: hasBadge ? size * 0.19 : size * 0.3, weight: .semibold))
                    .foregroundStyle(iconColor)
                if let badge = achievement.badge {
                    Text(badge)
                        .font(.archivo(badge.count > 3 ? size * 0.2 : size * 0.26, bold: true))
                        .foregroundStyle(textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: size * 0.6)
                }
            }
            .offset(y: size * 0.01)
        }
        .frame(width: size, height: size * 1.1)
        .overlay(alignment: .topLeading) {
            if let times, times > 1, !locked, size >= 60 {
                Text("×\(times)")
                    .font(.inter(size * 0.13, .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .background(Circle().fill(Theme.bg))
                    .overlay(Circle().strokeBorder(Theme.accent, lineWidth: max(size * 0.025, 1.5)))
                    .position(x: size * 0.86, y: size * 1.1 * 0.164)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(locked ? "\(achievement.title), ainda não ganha" : "\(achievement.title), ganha")
    }
}
