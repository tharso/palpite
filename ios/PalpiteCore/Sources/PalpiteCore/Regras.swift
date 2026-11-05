import Foundation

/// Cor de cada letra depois do palpite.
public enum Pista: String, Codable, Sendable {
    case certa   // verde: letra certa no lugar certo
    case lugar   // amarela: letra existe, em outro lugar
    case errada  // cinza: letra não existe

    var peso: Int {
        switch self {
        case .errada: 1
        case .lugar: 2
        case .certa: 3
        }
    }
}

/// Regras puras do jogo. Espelham o `game.js` do site, para o desafio
/// do dia ser o mesmo no site e no app.
public enum Regras {
    /// Letras por palavra que o jogador pode escolher.
    public static let tamanhos = [4, 5, 6, 7]
    public static let tentativas = 6

    /// Tira acentos e cedilha e põe em maiúsculas: "ação" -> "ACAO".
    public static func normalizar(_ palavra: String) -> String {
        palavra
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "pt_BR"))
            .uppercased()
    }

    /// Compara palpite e resposta (já normalizados).
    /// Letras repetidas: cada letra da resposta só "paga" uma pista.
    public static func avaliar(_ palpite: String, _ resposta: String) -> [Pista] {
        let p = Array(palpite), r = Array(resposta)
        var res = Array(repeating: Pista.errada, count: p.count)
        var sobra: [Character: Int] = [:]
        for i in r.indices {
            if i < p.count, p[i] == r[i] {
                res[i] = .certa
            } else {
                sobra[r[i], default: 0] += 1
            }
        }
        for i in p.indices where res[i] != .certa {
            if let n = sobra[p[i]], n > 0 {
                res[i] = .lugar
                sobra[p[i]] = n - 1
            }
        }
        return res
    }

    /// Melhor pista de cada letra do teclado: certa > lugar > errada.
    public static func estadoTeclado(palpites: [String], resposta: String) -> [Character: Pista] {
        var teclas: [Character: Pista] = [:]
        for palpite in palpites {
            for (letra, pista) in zip(palpite, avaliar(palpite, resposta)) {
                if let atual = teclas[letra], atual.peso >= pista.peso { continue }
                teclas[letra] = pista
            }
        }
        return teclas
    }

    /// Número do desafio do dia (1 = 1º de janeiro de 2026), pela data local.
    public static func numeroDoDia(_ data: Date, calendario: Calendar = .current) -> Int {
        let c = calendario.dateComponents([.year, .month, .day], from: data)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let hoje = utc.date(from: DateComponents(year: c.year, month: c.month, day: c.day))!
        let inicio = utc.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let dias = Int((hoje.timeIntervalSince(inicio) / 86_400).rounded(.down))
        return dias + 1
    }

    /// Embaralha sempre do mesmo jeito (mesmo algoritmo do site).
    public static func embaralhar<T>(_ lista: [T], semente: UInt32) -> [T] {
        var a = lista
        var s = semente
        func rand() -> Double {
            s = s &+ 0x6d2b_79f5
            var t = s
            t = (t ^ (t >> 15)) &* (t | 1)
            t ^= t &+ ((t ^ (t >> 7)) &* (t | 61))
            return Double(t ^ (t >> 14)) / 4_294_967_296
        }
        var i = a.count - 1
        while i > 0 {
            let j = Int((rand() * Double(i + 1)).rounded(.down))
            a.swapAt(i, j)
            i -= 1
        }
        return a
    }

    /// Cada tamanho tem a própria ordem. A semente de 5 letras é a original do site.
    public static func palavraDoDia(_ respostas: [String], numero: Int, tamanho: Int = 5) -> String {
        let ordem = embaralhar(respostas, semente: UInt32(20_260_101 + (tamanho - 5) * 7919))
        let n = ordem.count
        return ordem[(((numero - 1) % n) + n) % n]
    }

    /// Texto com quadradinhos coloridos para compartilhar.
    public static func textoCompartilhar(titulo: String, avaliacoes: [[Pista]], venceu: Bool) -> String {
        let placar = venceu ? "\(avaliacoes.count)/\(tentativas)" : "X/\(tentativas)"
        let linhas = avaliacoes.map { linha in
            linha.map { pista -> String in
                switch pista {
                case .certa: "🟩"
                case .lugar: "🟨"
                case .errada: "⬛"
                }
            }.joined()
        }
        return "\(titulo) \(placar)\n\n" + linhas.joined(separator: "\n")
    }
}
