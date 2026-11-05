import PalpiteCore
import SwiftUI

/// Teclado na tela, com a cor da melhor pista de cada letra.
struct Teclado: View {
    @EnvironmentObject private var loja: Loja
    private let fileiras = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]

    var body: some View {
        let estado = loja.teclado
        VStack(spacing: 7) {
            fileira(fileiras[0], estado)
            fileira(fileiras[1], estado)
            HStack(spacing: 5) {
                Tecla(rotulo: "⌫", largura: 1.6, fundo: Cor.tecla, rotuloAcessivel: "Apagar") { loja.apagar() }
                letras(fileiras[2], estado)
                Tecla(rotulo: "ENVIAR", largura: 1.6, fundo: Cor.certa, fonte: 12) { loja.enviar() }
            }
        }
        .frame(maxWidth: 500)
    }

    private func fileira(_ s: String, _ estado: [Character: Pista]) -> some View {
        HStack(spacing: 5) { letras(s, estado) }
    }

    private func letras(_ s: String, _ estado: [Character: Pista]) -> some View {
        ForEach(Array(s), id: \.self) { l in
            let pista = estado[l]
            Tecla(
                rotulo: String(l),
                fundo: pista.map { $0 == .errada ? Cor.teclaErrada : Cor.de($0) } ?? Cor.tecla,
                texto: pista == .lugar ? Cor.textoLugar : pista == .errada ? Color(hex: 0x77729A) : Cor.texto
            ) { loja.digitar(l) }
        }
    }
}

private struct Tecla: View {
    let rotulo: String
    var largura: CGFloat = 1
    var fundo: Color
    var texto: Color = Cor.texto
    var fonte: CGFloat = 17
    var rotuloAcessivel: String?
    let acao: () -> Void

    var body: some View {
        Button(action: acao) {
            Text(rotulo)
                .font(.arredondada(fonte))
                .foregroundStyle(texto)
                .frame(maxWidth: 44 * largura, minHeight: 54)
                .background(fundo, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(TeclaEstilo())
        .layoutPriority(largura)
        .accessibilityLabel(rotuloAcessivel ?? rotulo)
    }
}

private struct TeclaEstilo: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? 0.15 : 0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}
