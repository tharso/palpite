import PalpiteCore
import SwiftUI

/// Cores e fontes do Palpite (as mesmas do site).
enum Cor {
    static let fundo = Color(hex: 0x17152B)
    static let fundoTopo = Color(hex: 0x251F4A)
    static let painel = Color(hex: 0x221F3D)
    static let borda = Color(hex: 0x3B3860)
    static let texto = Color(hex: 0xF4F1FF)
    static let suave = Color(hex: 0xA9A4C9)
    static let certa = Color(hex: 0x22A06B)
    static let lugar = Color(hex: 0xE3A92B)
    static let errada = Color(hex: 0x67637F)
    static let tecla = Color(hex: 0x4A4670)
    static let teclaErrada = Color(hex: 0x2A2740)
    static let cursor = Color(hex: 0x8F88D6)
    static let erro = Color(hex: 0xE5484D)
    static let textoLugar = Color(hex: 0x2A1D00)

    static func de(_ pista: Pista) -> Color {
        switch pista {
        case .certa: certa
        case .lugar: lugar
        case .errada: errada
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255)
    }
}

extension Font {
    static func arredondada(_ tamanho: CGFloat, _ peso: Font.Weight = .bold) -> Font {
        .system(size: tamanho, weight: peso, design: .rounded)
    }
}

/// Vibração curta do iPhone. No Mac (testes), não faz nada.
enum Vibracao {
    @MainActor static func leve() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    @MainActor static func erro() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }

    @MainActor static func sucesso() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}

/// Faz a linha tremer quando o palpite é recusado.
struct Tremor: GeometryEffect {
    var vezes: CGFloat
    var animatableData: CGFloat {
        get { vezes }
        set { vezes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 7 * sin(vezes * .pi * 4), y: 0))
    }
}
