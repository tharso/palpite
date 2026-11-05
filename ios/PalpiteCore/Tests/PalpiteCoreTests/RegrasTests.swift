// Rodar: cd ios/PalpiteCore && swift test
import Foundation
import Testing
@testable import PalpiteCore

private func cores(_ p: String, _ r: String) -> String {
    Regras.avaliar(p, r).map { pista -> String in
        switch pista {
        case .certa: "V"
        case .lugar: "A"
        case .errada: "-"
        }
    }.joined()
}

private let palavras: Palavras = {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().appendingPathComponent("Palpite/palavras.json")
    return try! Palavras(json: Data(contentsOf: url))
}()
private let dicionario = palavras[5]

@Test func normalizarTiraAcento() {
    #expect(Regras.normalizar("ação") == "ACAO")
    #expect(Regras.normalizar("Nível") == "NIVEL")
}

@Test func coresBasicas() {
    #expect(cores("TERMO", "TERMO") == "VVVVV")
    #expect(cores("TERMO", "TEMOS") == "VV-AA")
}

@Test func letrasRepetidas() {
    #expect(cores("OSSOS", "BOLAS") == "A---V")
    #expect(cores("AAAAB", "BOLAS") == "---VA")
    #expect(cores("ALAAA", "BOLAS") == "-A-V-")
    #expect(cores("CASAS", "MASSA") == "-VVAA")
}

@Test func tecladoGuardaMelhorPista() {
    let t = Regras.estadoTeclado(palpites: ["CASAS", "MASSA"], resposta: "MASSA")
    #expect(t["C"] == .errada)
    #expect(t["M"] == .certa)
    #expect(t["A"] == .certa)
}

@Test func numeroDoDiaIgualAoSite() {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
    let d = { (a: Int, m: Int, dia: Int, h: Int) in cal.date(from: DateComponents(year: a, month: m, day: dia, hour: h))! }
    #expect(Regras.numeroDoDia(d(2026, 1, 1, 23), calendario: cal) == 1)
    #expect(Regras.numeroDoDia(d(2026, 1, 2, 0), calendario: cal) == 2)
    #expect(Regras.numeroDoDia(d(2026, 11, 5, 23), calendario: cal) == 309)
    #expect(Regras.numeroDoDia(d(2027, 1, 1, 0), calendario: cal) == 366)
}

@Test func palavraDoDiaIgualAoSite() {
    // Valores tirados do game.js do site.
    let esperado: [(Int, String)] = [(1, "surra"), (2, "cuida"), (309, "fugiu"), (310, "chego"), (1000, "pudim"), (5000, "tigre")]
    for (n, palavra) in esperado {
        #expect(Regras.palavraDoDia(dicionario.respostas, numero: n) == palavra)
    }
}

@Test func dicionarioCarrega() {
    #expect(dicionario.respostas.count > 1000)
    #expect(dicionario.comAcento("NIVEL") == "NÍVEL")
    #expect(!dicionario.aceita("XYZAB"))
    for r in dicionario.respostas {
        #expect(dicionario.validas[Regras.normalizar(r)] == r)
    }
}

@Test func partidaVitoria() {
    var p = Partida(modo: .livre, resposta: "fugiu")
    #expect(p.enviar("FUG", dicionario: dicionario) == .incompleta)
    #expect(p.enviar("XYZAB", dicionario: dicionario) == .naoExiste)
    #expect(p.palpites.isEmpty)
    #expect(p.enviar("TERMO", dicionario: dicionario) == .aceita([.errada, .errada, .errada, .errada, .errada]))
    #expect(p.enviar("FUGIU", dicionario: dicionario) == .aceita(Array(repeating: .certa, count: 5)))
    #expect(p.fim && p.venceu)
    #expect(p.enviar("TERMO", dicionario: dicionario) == .encerrada)
    var s = Estatisticas()
    s.registrar(p)
    #expect(s.jogos == 1 && s.vitorias == 1 && s.sequencia == 1 && s.distribuicao[1] == 1)
}

@Test func partidaDerrota() {
    var p = Partida(modo: .livre, resposta: "fugiu")
    for palavra in ["TERMO", "PRAIA", "CASAL", "BOLAS", "CINCO", "NIVEL"] {
        _ = p.enviar(palavra, dicionario: dicionario)
    }
    #expect(p.fim && !p.venceu)
    var s = Estatisticas()
    s.sequencia = 3
    s.registrar(p)
    #expect(s.sequencia == 0 && s.porcentagem == 0)
}

@Test func textoCompartilhar() {
    let t = Regras.textoCompartilhar(
        titulo: "Palpite #1",
        avaliacoes: [Regras.avaliar("TERMO", "TEMOS"), Regras.avaliar("TEMOS", "TEMOS")],
        venceu: true)
    #expect(t == "Palpite #1 2/6\n\n🟩🟩⬛🟨🟨\n🟩🟩🟩🟩🟩")
}

@Test func outrosTamanhos() throws {
    // Valores tirados do game.js do site (desafio nº 309).
    let esperado = [4: "rude", 6: "retire", 7: "tentará"]
    for n in [4, 6, 7] {
        let d = palavras[n]
        #expect(d.respostas.count > 400)
        for r in d.respostas { #expect(Regras.normalizar(r).count == n) }
        let dia = Regras.palavraDoDia(d.respostas, numero: 309, tamanho: n)
        #expect(dia == esperado[n])
    }
    #expect(Regras.palavraDoDia(dicionario.respostas, numero: 309, tamanho: 5) == "fugiu")
    #expect(Regras.avaliar("BANANA", "CABANA") == [.lugar, .certa, .errada, .certa, .certa, .certa])

    var p = Partida(modo: .livre, tamanho: 7, resposta: "tentará")
    #expect(p.enviar("TERMO", dicionario: palavras[7]) == .incompleta)
    #expect(p.enviar("TENTARA", dicionario: palavras[7]) == .aceita(Array(repeating: .certa, count: 7)))
    #expect(p.venceu)
}
