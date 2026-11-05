import Foundation

/// Lista de palavras: as que podem ser sorteadas e as aceitas como palpite.
public struct Dicionario: Sendable {
    public let respostas: [String]
    /// Chave sem acento ("NIVEL") -> forma com acento ("nível").
    public let validas: [String: String]

    public init(respostas: [String], validas: [String: String]) {
        self.respostas = respostas
        self.validas = validas
    }

    public func aceita(_ chave: String) -> Bool { validas[chave] != nil }

    /// "NIVEL" -> "NÍVEL". Se não achar, devolve a própria chave.
    public func comAcento(_ chave: String) -> String { (validas[chave] ?? chave).uppercased() }
}

/// Todas as listas, uma por tamanho, lidas do `palavras.json` (mesmo conteúdo do `palavras.js` do site).
public struct Palavras: Sendable {
    public let porTamanho: [Int: Dicionario]

    public init(json: Data) throws {
        struct Lista: Decodable { let respostas: [String]; let validas: [String: String] }
        let bruto = try JSONDecoder().decode([String: Lista].self, from: json)
        var mapa: [Int: Dicionario] = [:]
        for (k, v) in bruto {
            if let n = Int(k) { mapa[n] = Dicionario(respostas: v.respostas, validas: v.validas) }
        }
        porTamanho = mapa
    }

    public subscript(tamanho: Int) -> Dicionario { porTamanho[tamanho]! }
}

public enum Modo: String, Codable, CaseIterable, Sendable {
    case diario, livre
}

/// Uma partida: palavra secreta e palpites já enviados.
public struct Partida: Codable, Equatable, Sendable {
    public var modo: Modo
    public var tamanho: Int          // letras por palavra
    public var numero: Int?          // só no desafio do dia
    public var resposta: String      // com acento, minúscula: "fugiu", "nível"
    public var palpites: [String]    // chaves sem acento: "TERMO"
    public var fim = false
    public var venceu = false

    public init(modo: Modo, tamanho: Int = 5, numero: Int? = nil, resposta: String, palpites: [String] = []) {
        self.modo = modo
        self.tamanho = tamanho
        self.numero = numero
        self.resposta = resposta
        self.palpites = palpites
    }

    public var chave: String { Regras.normalizar(resposta) }
    public var avaliacoes: [[Pista]] { palpites.map { Regras.avaliar($0, chave) } }

    public enum Resultado: Equatable, Sendable {
        case incompleta          // faltam letras
        case naoExiste           // não está no dicionário
        case encerrada           // a partida já acabou
        case aceita([Pista])     // palpite registrado
    }

    /// Tenta registrar um palpite (letras A–Z, sem acento).
    public mutating func enviar(_ palpite: String, dicionario: Dicionario) -> Resultado {
        guard !fim else { return .encerrada }
        guard palpite.count == tamanho else { return .incompleta }
        guard dicionario.aceita(palpite) else { return .naoExiste }
        palpites.append(palpite)
        let pistas = Regras.avaliar(palpite, chave)
        if palpite == chave {
            fim = true
            venceu = true
        } else if palpites.count == Regras.tentativas {
            fim = true
        }
        return .aceita(pistas)
    }
}

/// Números de um modo de jogo.
public struct Estatisticas: Codable, Equatable, Sendable {
    public var jogos = 0
    public var vitorias = 0
    public var sequencia = 0
    public var melhor = 0
    public var distribuicao = Array(repeating: 0, count: Regras.tentativas)

    public init() {}

    public var porcentagem: Int { jogos == 0 ? 0 : Int((100 * Double(vitorias) / Double(jogos)).rounded()) }

    public mutating func registrar(_ partida: Partida) {
        jogos += 1
        if partida.venceu {
            vitorias += 1
            sequencia += 1
            melhor = max(melhor, sequencia)
            distribuicao[partida.palpites.count - 1] += 1
        } else {
            sequencia = 0
        }
    }
}
