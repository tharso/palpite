import Foundation
import PalpiteCore
import SwiftUI

/// Estado do jogo na tela e dados salvos no aparelho (UserDefaults).
@MainActor
final class Loja: ObservableObject {
    static let tempoVirar: UInt64 = 280_000_000 // ns entre uma letra e a próxima

    let palavras: Palavras
    private let defaults: UserDefaults

    @Published private(set) var modo: Modo
    @Published private(set) var tamanho: Int
    @Published private(set) var partida: Partida
    @Published private(set) var letras: [Character?]
    @Published var cursor = 0
    /// Quantas letras da última linha enviada já foram reveladas (animação).
    /// `Loja.todas` = nenhuma animação em andamento.
    @Published private(set) var revelados = Loja.todas
    static let todas = 99
    @Published private(set) var ocupado = false
    @Published private(set) var aviso: Aviso?
    @Published private(set) var tremores = 0
    @Published private(set) var linhaInvalida = false
    @Published private(set) var dancando = false
    @Published var mostrarAjuda = false
    @Published var mostrarFim = false

    struct Aviso: Equatable {
        let id = UUID()
        let texto: String
        let erro: Bool
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let url = Bundle.main.url(forResource: "palavras", withExtension: "json")!
        palavras = try! Palavras(json: Data(contentsOf: url))
        let m = Modo(rawValue: defaults.string(forKey: "modo") ?? "") ?? .diario
        let t = defaults.integer(forKey: "tamanho")
        let n = Regras.tamanhos.contains(t) ? t : 5
        modo = m
        tamanho = n
        letras = Array(repeating: nil, count: n)
        partida = Partida(modo: m, tamanho: n, resposta: "")
        partida = carregar(m)
        salvar()
        if !defaults.bool(forKey: "viuAjuda") {
            defaults.set(true, forKey: "viuAjuda")
            mostrarAjuda = true
        } else if partida.fim {
            mostrarFim = true
        }
    }

    // MARK: - Dados salvos

    var dicionario: Dicionario { palavras[tamanho] }
    private var chavePartida: String { "partida.\(modo.rawValue).\(tamanho)" }
    private var chaveEstatisticas: String { "estatisticas.\(modo.rawValue).\(tamanho)" }

    private func carregar(_ m: Modo) -> Partida {
        let salvo = defaults.data(forKey: "partida.\(m.rawValue).\(tamanho)")
            .flatMap { try? JSONDecoder().decode(Partida.self, from: $0) }
        switch m {
        case .diario:
            let n = Regras.numeroDoDia(Date())
            if let salvo, salvo.numero == n { return salvo }
            return Partida(modo: .diario, tamanho: tamanho, numero: n,
                           resposta: Regras.palavraDoDia(dicionario.respostas, numero: n, tamanho: tamanho))
        case .livre:
            if let salvo, !salvo.fim { return salvo }
            return novaLivre()
        }
    }

    private func novaLivre() -> Partida {
        Partida(modo: .livre, tamanho: tamanho, resposta: dicionario.respostas.randomElement()!)
    }

    private func salvar() {
        if let d = try? JSONEncoder().encode(partida) { defaults.set(d, forKey: chavePartida) }
    }

    func estatisticas() -> Estatisticas {
        defaults.data(forKey: chaveEstatisticas).flatMap { try? JSONDecoder().decode(Estatisticas.self, from: $0) } ?? Estatisticas()
    }

    private func registrarFim() {
        var s = estatisticas()
        s.registrar(partida)
        if let d = try? JSONEncoder().encode(s) { defaults.set(d, forKey: chaveEstatisticas) }
    }

    // MARK: - Leitura para a tela

    var linhaAtual: Int { partida.palpites.count }
    var avaliacoes: [[Pista]] { partida.avaliacoes }
    var teclado: [Character: Pista] {
        // Durante a animação, a última linha ainda não conta no teclado.
        let palpites = revelados < tamanho ? Array(partida.palpites.dropLast()) : partida.palpites
        return Regras.estadoTeclado(palpites: palpites, resposta: partida.chave)
    }
    func comAcento(_ chave: String) -> String { dicionario.comAcento(chave) }

    // MARK: - Jogada

    func digitar(_ l: Character) {
        guard !partida.fim, !ocupado else { return }
        linhaInvalida = false
        letras[cursor] = l
        Vibracao.leve()
        if let prox = letras.indices.first(where: { $0 > cursor && letras[$0] == nil }) {
            cursor = prox
        } else {
            cursor = min(cursor + 1, tamanho - 1)
        }
    }

    func apagar() {
        guard !partida.fim, !ocupado else { return }
        linhaInvalida = false
        if letras[cursor] != nil {
            letras[cursor] = nil
        } else if cursor > 0 {
            cursor -= 1
            letras[cursor] = nil
        }
    }

    func escolher(coluna: Int) {
        guard !partida.fim, !ocupado else { return }
        cursor = coluna
    }

    func enviar() {
        guard !partida.fim, !ocupado else { return }
        let palpite = String(letras.compactMap { $0 })
        switch partida.enviar(palpite, dicionario: dicionario) {
        case .incompleta: recusar("Só palavras com \(tamanho) letras")
        case .naoExiste: recusar("Essa palavra não está no dicionário")
        case .encerrada: break
        case .aceita:
            // Na mesma hora em que o palpite entra, a linha fica "não revelada".
            // Se isso esperasse a Task começar, a linha piscaria colorida antes da animação.
            ocupado = true
            revelados = 0
            letras = Array(repeating: nil, count: tamanho)
            cursor = 0
            salvar()
            if partida.fim { registrarFim() }
            Task { await revelar() }
        }
    }

    private func recusar(_ texto: String) {
        avisar(texto, erro: true)
        linhaInvalida = true
        tremores += 1
        Vibracao.erro()
    }

    private func revelar() async {
        for i in 1...tamanho {
            try? await Task.sleep(nanoseconds: Self.tempoVirar)
            withAnimation(.easeInOut(duration: 0.25)) { revelados = i }
        }
        try? await Task.sleep(nanoseconds: 250_000_000)
        revelados = Self.todas
        ocupado = false
        guard partida.fim else { return }
        if partida.venceu {
            Vibracao.sucesso()
            dancando = true
            let frases = ["Genial!", "Incrível!", "Muito bem!", "Boa!", "Ufa, deu!", "No limite!"]
            avisar(frases[partida.palpites.count - 1])
            try? await Task.sleep(nanoseconds: 1_300_000_000)
        } else {
            Vibracao.erro()
            avisar("A palavra era " + comAcento(partida.chave), duracao: 2.6)
            try? await Task.sleep(nanoseconds: 1_800_000_000)
        }
        mostrarFim = true
    }

    private func avisar(_ texto: String, erro: Bool = false, duracao: Double = 2) {
        let a = Aviso(texto: texto, erro: erro)
        withAnimation(.easeOut(duration: 0.2)) { aviso = a }
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duracao * 1_000_000_000))
            if aviso == a { withAnimation(.easeIn(duration: 0.2)) { aviso = nil } }
        }
    }

    // MARK: - Modos

    func trocar(para m: Modo) {
        guard !ocupado, m != modo else { return }
        modo = m
        defaults.set(m.rawValue, forKey: "modo")
        partida = carregar(m)
        recomecarLinha()
        salvar()
        if partida.fim { mostrarFim = true }
    }

    func trocar(tamanho n: Int) {
        guard !ocupado, n != tamanho, Regras.tamanhos.contains(n) else { return }
        tamanho = n
        defaults.set(n, forKey: "tamanho")
        partida = carregar(modo)
        recomecarLinha()
        salvar()
        mostrarFim = partida.fim
    }

    func jogarDeNovo() {
        mostrarFim = false
        if modo == .livre {
            partida = novaLivre()
            recomecarLinha()
            salvar()
        } else {
            trocar(para: .livre)
        }
    }

    private func recomecarLinha() {
        letras = Array(repeating: nil, count: tamanho)
        cursor = 0
        revelados = Self.todas
        linhaInvalida = false
        dancando = false
    }

    /// Volta o desafio do dia quando o app fica aberto de um dia para o outro.
    func conferirNovoDia() {
        guard modo == .diario, !ocupado, partida.numero != Regras.numeroDoDia(Date()) else { return }
        partida = carregar(.diario)
        recomecarLinha()
        salvar()
        mostrarFim = false
    }

    var textoCompartilhar: String {
        let titulo = modo == .diario
            ? "Palpite #\(partida.numero ?? 0) · \(tamanho) letras"
            : "Palpite (modo livre, \(tamanho) letras)"
        return Regras.textoCompartilhar(titulo: titulo, avaliacoes: avaliacoes, venceu: partida.venceu)
            + "\npalpite.tharso.com"
    }
}
