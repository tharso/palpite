import PalpiteCore
import SwiftUI

/// Tela principal: topo, modos, grade, aviso e teclado.
struct JogoView: View {
    @EnvironmentObject private var loja: Loja

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [Cor.fundoTopo, Cor.fundo], startPoint: .top, endPoint: .center)
                .ignoresSafeArea()

            VStack(spacing: 6) {
                Topo()
                SeletorModo()
                SeletorTamanho()
                GeometryReader { geo in
                    let n = CGFloat(loja.tamanho)
                    let lado = min(62, (geo.size.width - 6 * (n - 1)) / n, geo.size.height / 7.8)
                    VStack(spacing: 10) {
                        Text(loja.modo == .diario
                             ? "DESAFIO Nº \(loja.partida.numero ?? 0) · \(loja.tamanho) LETRAS"
                             : "MODO LIVRE · \(loja.tamanho) LETRAS")
                            .font(.arredondada(13, .semibold))
                            .kerning(1)
                            .foregroundStyle(Cor.suave)
                        Grade(lado: lado)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                Teclado()
                    .padding(.bottom, 4)
            }
            .padding(.horizontal, 8)

            if let aviso = loja.aviso {
                Text(aviso.texto)
                    .font(.arredondada(16))
                    .foregroundStyle(aviso.erro ? .white : Cor.fundo)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(aviso.erro ? Cor.erro : Cor.texto, in: RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.45), radius: 12, y: 6)
                    .padding(.top, 96)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .accessibilityAddTraits(.isStaticText)
                    .zIndex(1)
            }
        }
        .foregroundStyle(Cor.texto)
        .sheet(isPresented: $loja.mostrarAjuda) { AjudaView() }
        .sheet(isPresented: $loja.mostrarFim) { FimView().environmentObject(loja) }
    }
}

// MARK: - Topo

private struct Topo: View {
    @EnvironmentObject private var loja: Loja

    var body: some View {
        HStack {
            BotaoIcone(sistema: "questionmark", rotulo: "Como jogar") { loja.mostrarAjuda = true }
            Spacer()
            Marca()
            Spacer()
            BotaoIcone(sistema: "chart.bar.fill", rotulo: "Estatísticas") { loja.mostrarFim = true }
        }
        .padding(.top, 6)
    }
}

struct Marca: View {
    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array("PALPITE".enumerated()), id: \.offset) { i, letra in
                let cor: Color = i == 0 || i == 4 ? Cor.certa : i == 2 ? Cor.lugar : Cor.painel
                Text(String(letra))
                    .font(.arredondada(18, .heavy))
                    .foregroundStyle(i == 2 ? Cor.textoLugar : Cor.texto)
                    .frame(width: 28, height: 30)
                    .background(cor, in: RoundedRectangle(cornerRadius: 7))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(cor == Cor.painel ? Cor.borda : cor, lineWidth: 1))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Palpite")
    }
}

private struct BotaoIcone: View {
    let sistema: String
    let rotulo: String
    let acao: () -> Void

    var body: some View {
        Button(action: acao) {
            Image(systemName: sistema)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 38, height: 38)
                .background(Cor.painel, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Cor.borda, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(rotulo)
    }
}

private struct SeletorModo: View {
    @EnvironmentObject private var loja: Loja

    var body: some View {
        HStack(spacing: 4) {
            botao("Desafio do dia", .diario)
            botao("Modo livre", .livre)
        }
        .padding(3)
        .background(Cor.painel, in: Capsule())
        .overlay(Capsule().stroke(Cor.borda, lineWidth: 1))
    }

    private func botao(_ titulo: String, _ m: Modo) -> some View {
        let ativo = loja.modo == m
        return Button { loja.trocar(para: m) } label: {
            Text(titulo)
                .font(.arredondada(14, .semibold))
                .foregroundStyle(ativo ? Cor.texto : Cor.suave)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(ativo ? Cor.tecla : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(ativo ? .isSelected : [])
    }
}

private struct SeletorTamanho: View {
    @EnvironmentObject private var loja: Loja

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Regras.tamanhos, id: \.self) { n in
                let ativo = loja.tamanho == n
                Button { loja.trocar(tamanho: n) } label: {
                    VStack(spacing: 0) {
                        Text("\(n)").font(.arredondada(16, .heavy)).foregroundStyle(Cor.texto)
                        Text("LETRAS").font(.arredondada(9, .semibold)).foregroundStyle(Cor.suave)
                    }
                    .frame(width: 52, height: 38)
                    .background(ativo ? Cor.tecla : Cor.painel, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(ativo ? Cor.cursor : Cor.borda, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(n) letras")
                .accessibilityAddTraits(ativo ? .isSelected : [])
            }
        }
        .padding(.top, 2)
    }
}

// MARK: - Grade

private struct Grade: View {
    @EnvironmentObject private var loja: Loja
    let lado: CGFloat

    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<Regras.tentativas, id: \.self) { linha in
                HStack(spacing: 6) {
                    ForEach(0..<loja.tamanho, id: \.self) { col in
                        Ladrilho(estado: estado(linha, col), lado: lado, atraso: Double(col) * 0.09)
                            .onTapGesture {
                                if linha == loja.linhaAtual { loja.escolher(coluna: col) }
                            }
                    }
                }
                .modifier(Tremor(vezes: linha == loja.linhaAtual ? CGFloat(loja.tremores) : 0))
                .animation(.linear(duration: 0.4), value: loja.tremores)
            }
        }
    }

    private func estado(_ linha: Int, _ col: Int) -> Ladrilho.Estado {
        let p = loja.partida
        if linha < p.palpites.count {
            let chave = p.palpites[linha]
            let ultima = linha == p.palpites.count - 1
            if ultima && col >= loja.revelados {
                return .enviada(Array(chave)[col])
            }
            let letra = Array(loja.comAcento(chave))[col]
            return .revelada(letra, loja.avaliacoes[linha][col], dancar: ultima && loja.dancando)
        }
        if linha == p.palpites.count && !p.fim {
            return .atual(loja.letras[col], cursor: col == loja.cursor, invalida: loja.linhaInvalida)
        }
        return .vazia
    }
}

struct Ladrilho: View {
    enum Estado: Equatable {
        case vazia
        case atual(Character?, cursor: Bool, invalida: Bool)
        case enviada(Character)
        case revelada(Character, Pista, dancar: Bool)
    }

    let estado: Estado
    let lado: CGFloat
    var atraso: Double = 0
    @State private var giro: Double = 0
    @State private var pulo: CGFloat = 0

    var body: some View {
        Text(letra.map(String.init) ?? " ")
            .font(.arredondada(lado * 0.52, .heavy))
            .foregroundStyle(corTexto)
            .frame(width: lado, height: lado)
            .background(fundo, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(borda, lineWidth: 2))
            .shadow(color: cursor ? Cor.cursor.opacity(0.35) : .clear, radius: 3)
            .rotation3DEffect(.degrees(giro), axis: (x: 1, y: 0, z: 0))
            .offset(y: pulo)
            .contentShape(Rectangle())
            .onChange(of: revelada) { agora in
                guard agora else { return }
                giro = 90
                withAnimation(.easeOut(duration: 0.25)) { giro = 0 }
            }
            .onChange(of: dancar) { agora in
                guard agora else { return }
                withAnimation(.easeOut(duration: 0.18).delay(atraso)) { pulo = -14 }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(atraso + 0.18)) { pulo = 0 }
            }
            .accessibilityLabel(descricao)
    }

    private var letra: Character? {
        switch estado {
        case .vazia: nil
        case .atual(let l, _, _): l
        case .enviada(let l): l
        case .revelada(let l, _, _): l
        }
    }

    private var revelada: Bool { if case .revelada = estado { true } else { false } }
    private var dancar: Bool { if case .revelada(_, _, let d) = estado { d } else { false } }
    private var cursor: Bool { if case .atual(_, let c, _) = estado { c } else { false } }

    private var fundo: Color {
        switch estado {
        case .vazia: .clear
        case .atual: Cor.painel
        case .enviada: Cor.painel
        case .revelada(_, let p, _): Cor.de(p)
        }
    }

    private var borda: Color {
        switch estado {
        case .vazia: Color.white.opacity(0.07)
        case .atual(_, let c, let inv): inv ? Cor.erro : c ? Cor.cursor : Cor.borda
        case .enviada: Cor.borda
        case .revelada(_, let p, _): Cor.de(p)
        }
    }

    private var corTexto: Color {
        if case .revelada(_, .lugar, _) = estado { return Cor.textoLugar }
        return Cor.texto
    }

    private var descricao: String {
        guard let l = letra else { return "vazio" }
        switch estado {
        case .revelada(_, .certa, _): return "\(l), certa"
        case .revelada(_, .lugar, _): return "\(l), em outro lugar"
        case .revelada(_, .errada, _): return "\(l), não existe"
        default: return String(l)
        }
    }
}
