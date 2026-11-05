import PalpiteCore
import SwiftUI

// MARK: - Como jogar

struct AjudaView: View {
    @Environment(\.dismiss) private var fechar

    var body: some View {
        Janela(titulo: "Como jogar", fechar: { fechar() }) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Descubra a palavra secreta em até **6 tentativas**. Escolha palavras de **4, 5, 6 ou 7 letras** nos botões do topo.")
                Text("Cada palpite precisa ser uma palavra que existe. Depois de enviar, as letras mudam de cor:")
                exemplo("CARTA", indice: 0, pista: .certa)
                Text("**Verde:** a letra está na palavra e na posição certa.")
                exemplo("MOLHO", indice: 2, pista: .lugar)
                Text("**Amarela:** a letra está na palavra, mas em outra posição.")
                exemplo("PRAIA", indice: 3, pista: .errada)
                Text("**Cinza:** a letra não está na palavra.")
                Text("Acentos e cedilha entram sozinhos. Digite **acao** e o jogo entende **ação**.")
                Text("A palavra pode ter letras repetidas.")
                Text("Toque num quadrado da linha para escolher onde a próxima letra entra.")
                Text("**Desafio do dia:** uma palavra nova por dia em cada tamanho, igual para todo mundo.\n**Modo livre:** jogue quantas vezes quiser.")
            }
            .font(.system(size: 16, design: .rounded))
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func exemplo(_ palavra: String, indice: Int, pista: Pista) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(palavra.enumerated()), id: \.offset) { i, l in
                Ladrilho(estado: i == indice ? .revelada(l, pista, dancar: false) : .atual(l, cursor: false, invalida: false), lado: 38)
            }
        }
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Fim de partida e estatísticas

struct FimView: View {
    @EnvironmentObject private var loja: Loja
    @Environment(\.dismiss) private var fechar

    var body: some View {
        let p = loja.partida
        let s = loja.estatisticas()
        Janela(titulo: p.fim ? (p.venceu ? "Você acertou! 🎉" : "Não foi dessa vez") : "Estatísticas",
               alturas: [.fraction(0.68), .large], fechar: { fechar() }) {
            VStack(alignment: .leading, spacing: 14) {
                if p.fim {
                    (Text("A palavra era ").foregroundColor(Cor.suave)
                        + Text(p.resposta.uppercased()).font(.arredondada(22, .heavy)).kerning(2))
                }

                Secao((loja.modo == .diario ? "Estatísticas — desafio do dia" : "Estatísticas — modo livre") + ", \(loja.tamanho) letras")
                HStack {
                    numero("\(s.jogos)", "jogos")
                    numero("\(s.porcentagem)%", "vitórias")
                    numero("\(s.sequencia)", "sequência")
                    numero("\(s.melhor)", "melhor seq.")
                }

                Secao("Tentativas usadas")
                VStack(spacing: 4) {
                    let maximo = max(1, s.distribuicao.max() ?? 1)
                    ForEach(0..<Regras.tentativas, id: \.self) { i in
                        let n = s.distribuicao[i]
                        let destaque = p.fim && p.venceu && p.palpites.count == i + 1
                        HStack(spacing: 6) {
                            Text("\(i + 1)").font(.arredondada(13, .medium)).frame(width: 14)
                            GeometryReader { g in
                                Text("\(n)")
                                    .font(.arredondada(13))
                                    .padding(.horizontal, 6)
                                    .frame(width: max(24, g.size.width * CGFloat(n) / CGFloat(maximo)), alignment: .trailing)
                                    .frame(height: 20)
                                    .background(destaque ? Cor.certa : Cor.tecla, in: RoundedRectangle(cornerRadius: 4))
                            }
                            .frame(height: 20)
                        }
                    }
                }

                if p.fim {
                    HStack(spacing: 8) {
                        ShareLink(item: loja.textoCompartilhar) {
                            Label("Compartilhar", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(BotaoGrande(cor: Cor.tecla))

                        Button(loja.modo == .livre ? "Jogar de novo" : "Modo livre") { loja.jogarDeNovo() }
                            .buttonStyle(BotaoGrande(cor: Cor.certa))
                    }
                    .padding(.top, 4)

                    if loja.modo == .diario {
                        Contagem()
                    }
                }
            }
        }
    }

    private func numero(_ valor: String, _ rotulo: String) -> some View {
        VStack(spacing: 2) {
            Text(valor).font(.arredondada(28, .heavy))
            Text(rotulo).font(.arredondada(11, .medium)).foregroundStyle(Cor.suave)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// Tempo até a próxima palavra do dia.
private struct Contagem: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let cal = Calendar.current
            let amanha = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: ctx.date)!)
            let s = max(0, Int(amanha.timeIntervalSince(ctx.date)))
            Text(String(format: "Nova palavra em %02d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60))
                .font(.arredondada(14, .medium).monospacedDigit())
                .foregroundStyle(Cor.suave)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Peças comuns

struct Janela<Conteudo: View>: View {
    let titulo: String
    var alturas: Set<PresentationDetent> = [.large]
    let fechar: () -> Void
    @ViewBuilder let conteudo: Conteudo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(titulo).font(.arredondada(24, .heavy))
                    Spacer()
                    Button(action: fechar) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Cor.suave)
                            .frame(width: 32, height: 32)
                            .background(Cor.fundo, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Fechar")
                }
                conteudo
            }
            .padding(22)
        }
        .foregroundStyle(Cor.texto)
        .background(Cor.painel.ignoresSafeArea())
        .presentationDetents(alturas)
        .presentationDragIndicator(.visible)
    }
}

private struct Secao: View {
    let texto: String
    init(_ texto: String) { self.texto = texto }

    var body: some View {
        Text(texto.uppercased())
            .font(.arredondada(13, .semibold))
            .kerning(1)
            .foregroundStyle(Cor.suave)
            .padding(.top, 4)
    }
}

struct BotaoGrande: ButtonStyle {
    let cor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.arredondada(16))
            .foregroundStyle(Cor.texto)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(cor, in: RoundedRectangle(cornerRadius: 12))
            .brightness(configuration.isPressed ? 0.1 : 0)
    }
}
