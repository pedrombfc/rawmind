import SwiftUI
import CoreText

/// Cores e fontes do Rawmind (mesmas do design aprovado).
enum Theme {
    static let bg = Color(hex: 0x0E0E0C)
    static let card = Color(hex: 0x1A1916)
    static let text = Color(hex: 0xEDEBE4)
    static let muted = Color(hex: 0x9A978E)
    static let accent = Color(hex: 0xF2A93B)
    static let done = Color(hex: 0x7FB8A4)
    static let doneBg = Color(hex: 0x16231E)
    static let track = Color(hex: 0x2A2925)
    static let border = Color(hex: 0x4A4842)
    static let chipBorder = Color(hex: 0x3A3833)

    /// Carrega as fontes Archivo e Inter que estão dentro do app.
    static func registerFonts() {
        let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

enum InterWeight: String {
    case regular = "Inter-Regular"
    case medium = "Inter-Medium"
    case semibold = "Inter-SemiBold"
}

extension Font {
    /// Títulos (Archivo).
    static func archivo(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "Archivo-Bold" : "Archivo-ExtraBold", size: size)
    }

    /// Texto (Inter).
    static func inter(_ size: CGFloat, _ weight: InterWeight = .regular) -> Font {
        .custom(weight.rawValue, size: size)
    }
}
