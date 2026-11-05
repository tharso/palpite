import sys, json, unicodedata, re
dic_path, freq_path, out_path = sys.argv[1:4]
ALLOWED = set("abcdefghijklmnopqrstuvwxyzáàâãéêíóôõúüç")
def norm(w):
    return ''.join(c for c in unicodedata.normalize('NFD', w) if unicodedata.category(c) != 'Mn')
dic = set()
for line in open(dic_path, encoding='utf-8'):
    w = line.strip()
    if not w or w[0].isupper(): continue
    w = unicodedata.normalize('NFC', w)
    if set(w) <= ALLOWED: dic.add(w)
rank = {}
for i, line in enumerate(open(freq_path, encoding='utf-8')):
    w = unicodedata.normalize('NFC', line.split()[0].lower())
    rank.setdefault(w, i)
five = [w for w in dic if len(norm(w)) == 5]
valid = {}
for w in five:
    k = norm(w).upper()
    if k not in valid or rank.get(w, 10**9) < rank.get(valid[k], 10**9):
        valid[k] = w
BLOCK = set("porra merda bosta putas foder fodam fodeu fodes cuzao bunda pinto rolas tesao viado bicha nazis drogas jesus joana chico cairo negao orgia peido omega morse maria pedro paulo sexys bicho droga matar morto morte matou mataram nazis vadia piranha cacete bruxa".split())
answers = []
for k, w in valid.items():
    r = rank.get(w)
    if r is None or r > 12000: continue
    if norm(w) in BLOCK: continue
    if w.endswith('s') and (w[:-1] in dic or w[:-2] in dic): continue  # plural
    answers.append((r, w))
answers.sort()
ans = [w for _, w in answers]
print(len(valid), 'valid;', len(ans), 'answers', file=sys.stderr)
print(' '.join(ans[:200]), file=sys.stderr)
print('...', ' '.join(ans[-80:]), file=sys.stderr)
with open(out_path, 'w', encoding='utf-8') as f:
    f.write('// Gerado por tools/build_words.py. Fontes: dicionário br-utf8 (IME-USP) e FrequencyWords pt_br (hermitdave, CC-BY-SA 4.0).\n')
    f.write('// RESPOSTAS: palavras comuns que podem ser sorteadas. VALIDAS: chave sem acento -> forma com acento.\n')
    f.write('const RESPOSTAS = ' + json.dumps(ans, ensure_ascii=False) + ';\n')
    f.write('const VALIDAS = ' + json.dumps(dict(sorted(valid.items())), ensure_ascii=False, separators=(',',':')) + ';\n')
    f.write("if (typeof module !== 'undefined') module.exports = { RESPOSTAS, VALIDAS };\n")
