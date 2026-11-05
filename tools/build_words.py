"""Gera as listas de palavras de 4 a 7 letras do jogo.

Uso: python3 tools/build_words.py br-utf8.txt pt_br_50k.txt palavras.js ios/Palpite/palavras.json

- VALIDAS: palavras aceitas como palpite (chave sem acento -> forma com acento).
- RESPOSTAS: palavras comuns que podem ser sorteadas.

ATENÇÃO: mudar a lista de RESPOSTAS de um tamanho muda o desafio do dia daquele tamanho.
A lista de 5 letras precisa continuar idêntica (o jogo começou com ela).
"""
import json, sys, unicodedata

dic_path, freq_path, out_js, out_json = sys.argv[1:5]
TAMANHOS = (4, 5, 6, 7)
CORTE = 12000  # só palavras entre as 12 mil mais usadas viram resposta
ALLOWED = set("abcdefghijklmnopqrstuvwxyzáàâãéêíóôõúüç")

# Palavras que não podem ser sorteadas: palavrões, nomes próprios, violência, drogas.
BLOQUEIO = {
    5: "porra merda bosta putas foder fodam fodeu fodes cuzao bunda pinto rolas tesao viado bicha nazis drogas jesus joana chico cairo negao orgia peido omega morse maria pedro paulo sexys bicho droga matar morto morte matou mataram nazis vadia piranha cacete bruxa",
    4: "puta pica rola cona piru xota cuzo caga mijo peru nazi deus jose joao rita ana bebe sexo pau puto sata roma noel nina tito sara adao buda gabe liam dana dane cuba opio babe tina deem polo",
    6: "buceta cacete piroca xoxota punhet foderam fodido fodida viados bichas bunduda matado mortos matava matará morrer drogas nazista safada pentel cuzões porrada daniel walter carlos cristo alicia miguel helena serena regina rafael felipe xavier garcia europa franca mexico russia italia brasil moscou suecia grecia veneza coreia nevada babaca safado transa trepar tarado vagina erecao bordel chupar sexual pelado pelada ferrar ferrou otario aborto bridge",
    7: "caralho punheta boquete putaria estupro nazista cocaína heroína suicida assassino matando morrendo matamos drogado drogada estupra maconha transar transou transei maricas orgasmo esperma cafetao gostosa gostoso piranha satanas gozando chapado sexuais tortura matarei mataram mataria matarao matasse matarem matador matanca baleado cadaver morfina imbecil imbecis cretino canalha gabriel antonio roberto alfredo alberto orlando barbara florida holanda irlanda noruega turquia escocia espanha polonia america genebra messias trailer trafico",
}


def norm(w):
    return ''.join(c for c in unicodedata.normalize('NFD', w) if unicodedata.category(c) != 'Mn')


dic = set()
for line in open(dic_path, encoding='utf-8'):
    w = line.strip()
    if not w or w[0].isupper():
        continue
    w = unicodedata.normalize('NFC', w)
    if set(w) <= ALLOWED:
        dic.add(w)

dic_sem_acento = {norm(w) for w in dic}

rank = {}
for i, line in enumerate(open(freq_path, encoding='utf-8')):
    w = unicodedata.normalize('NFC', line.split()[0].lower())
    rank.setdefault(w, i)

def plural_irregular(w):
    """Plurais que o teste simples (tirar o "s") não pega: aviões, papéis, níveis, jovens, juízes."""
    trocas = [('ões', 'ão'), ('ães', 'ão'), ('éis', 'el'), ('eis', 'el'), ('eis', 'il'), ('óis', 'ol'),
              ('uis', 'ul'), ('ais', 'al'), ('ns', 'm'), ('zes', 'z'), ('res', 'r'), ('ses', 's')]
    return any(w.endswith(fim) and norm(w[:-len(fim)] + troca) in dic_sem_acento for fim, troca in trocas)


saida = {}
for n in TAMANHOS:
    validas = {}
    for w in dic:
        if len(norm(w)) != n:
            continue
        k = norm(w).upper()
        # Forma escolhida: a mais usada; no empate, a com menos acentos; depois, ordem alfabética.
        chave = lambda x: (rank.get(x, 10**9), sum(c not in 'abcdefghijklmnopqrstuvwxyz' for c in x), x)
        if k not in validas or chave(w) < chave(validas[k]):
            validas[k] = w
    bloqueio = {norm(b) for b in BLOQUEIO[n].split()}
    respostas = []
    for k, w in validas.items():
        r = rank.get(w)
        if r is None or r > CORTE or norm(w) in bloqueio:
            continue
        if w.endswith('s') and (w[:-1] in dic or w[:-2] in dic):
            continue  # plural
        if n != 5 and plural_irregular(w):
            continue  # a lista de 5 letras fica como nasceu, para não mudar o desafio do dia
        respostas.append((r, w))
    respostas.sort()
    saida[n] = {'respostas': [w for _, w in respostas], 'validas': dict(sorted(validas.items()))}
    print(f'{n} letras: {len(validas)} válidas, {len(respostas)} respostas', file=sys.stderr)

with open(out_js, 'w', encoding='utf-8') as f:
    f.write('// Gerado por tools/build_words.py. Não editar à mão.\n')
    f.write('// Fontes: dicionário br-utf8 (IME-USP) e FrequencyWords pt_br (Hermit Dave, CC-BY-SA 4.0).\n')
    f.write('// PALAVRAS[tamanho] = { respostas: [...palavras que podem ser sorteadas], validas: { SEMACENTO: "com acento" } }\n')
    f.write('const PALAVRAS = ' + json.dumps({str(n): v for n, v in saida.items()}, ensure_ascii=False, separators=(',', ':')) + ';\n')
    f.write("if (typeof module !== 'undefined') module.exports = { PALAVRAS };\n")

with open(out_json, 'w', encoding='utf-8') as f:
    json.dump({str(n): v for n, v in saida.items()}, f, ensure_ascii=False, separators=(',', ':'))
