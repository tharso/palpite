// Rodar: node --test tests/
const test = require('node:test');
const assert = require('node:assert');
const J = require('../game.js');
const { PALAVRAS } = require('../palavras.js');
const { respostas: RESPOSTAS, validas: VALIDAS } = PALAVRAS[5];

const cores = (p, r) => J.avaliar(p, r).map((c) => ({ certa: 'V', lugar: 'A', errada: '-' }[c])).join('');

test('normalizar tira acento e cedilha', () => {
  assert.strictEqual(J.normalizar('ação'), 'ACAO');
  assert.strictEqual(J.normalizar('Nível'), 'NIVEL');
});

test('acerto total fica todo verde', () => {
  assert.strictEqual(cores('TERMO', 'TERMO'), 'VVVVV');
});

test('verde, amarelo e cinza', () => {
  // resposta TEMOS, palpite TERMO: T e E certos; R não existe; M e O fora do lugar
  assert.strictEqual(cores('TERMO', 'TEMOS'), 'VV-AA');
});

test('letra repetida no palpite só ganha a pista que existe', () => {
  // BOLAS tem um O só: o primeiro O ganha amarelo, o segundo fica cinza
  assert.strictEqual(cores('OSSOS', 'BOLAS'), 'A---V');
  // verde tem prioridade: o A certo não deixa sobra para os outros A
  assert.strictEqual(cores('AAAAB', 'BOLAS'), '---VA');
  assert.strictEqual(cores('ALAAA', 'BOLAS'), '-A-V-');
  // MASSA tem 2 A e 2 S: CASAS -> C cinza, A e S verdes, A e S amarelos
  assert.strictEqual(cores('CASAS', 'MASSA'), '-VVAA');
});

test('teclado guarda a melhor pista de cada letra', () => {
  const ps = ['CASAS', 'MASSA'];
  const av = ps.map((p) => J.avaliar(p, 'MASSA'));
  const t = J.estadoTeclado(ps, av);
  assert.strictEqual(t.C, 'errada');
  assert.strictEqual(t.M, 'certa');
  assert.strictEqual(t.A, 'certa');
});

test('desafio do dia: número e palavra estáveis', () => {
  assert.strictEqual(J.numeroDoDia(new Date(2026, 0, 1, 23, 0)), 1);
  assert.strictEqual(J.numeroDoDia(new Date(2026, 0, 2, 0, 1)), 2);
  const a = J.palavraDoDia(RESPOSTAS, 309);
  assert.strictEqual(a, J.palavraDoDia(RESPOSTAS, 309));
  assert.notStrictEqual(J.palavraDoDia(RESPOSTAS, 309), J.palavraDoDia(RESPOSTAS, 310));
  assert.ok(RESPOSTAS.includes(a));
});

test('listas de palavras', () => {
  assert.ok(RESPOSTAS.length > 1000);
  for (const w of RESPOSTAS) {
    const k = J.normalizar(w);
    assert.strictEqual(k.length, 5, w);
    assert.strictEqual(VALIDAS[k], w, w);
  }
  assert.strictEqual(VALIDAS.NIVEL, 'nível');
  assert.strictEqual(VALIDAS.XYZAB, undefined);
});

test('texto para compartilhar', () => {
  const t = J.textoCompartilhar('Palpite #1', [J.avaliar('TERMO', 'TEMOS'), J.avaliar('TEMOS', 'TEMOS')], true);
  assert.strictEqual(t, 'Palpite #1 2/6\n\n🟩🟩⬛🟨🟨\n🟩🟩🟩🟩🟩');
});

test('desafio de 5 letras não mudou com os novos tamanhos', () => {
  // Palavras que o site já sorteava antes dos tamanhos 4, 6 e 7.
  assert.deepStrictEqual([1, 2, 309, 310, 1000].map((n) => J.palavraDoDia(RESPOSTAS, n)), ['surra', 'cuida', 'fugiu', 'chego', 'pudim']);
  assert.strictEqual(J.palavraDoDia(RESPOSTAS, 309, 5), 'fugiu');
});

test('listas de 4, 6 e 7 letras', () => {
  for (const n of [4, 6, 7]) {
    const { respostas, validas } = PALAVRAS[n];
    assert.ok(respostas.length > 400, `${n}: ${respostas.length}`);
    for (const w of respostas) {
      const k = J.normalizar(w);
      assert.strictEqual(k.length, n, w);
      assert.strictEqual(validas[k], w, w);
    }
    const dia = J.palavraDoDia(respostas, 309, n);
    assert.strictEqual(J.normalizar(dia).length, n);
  }
  // Cores funcionam em qualquer tamanho. CABANA: o B existe (amarelo), o 1º N sobra (cinza).
  assert.deepStrictEqual(J.avaliar('BANANA', 'CABANA'), ['lugar', 'certa', 'errada', 'certa', 'certa', 'certa']);
});

test('aceita palavras que faltavam no dicionário do IME-USP', () => {
  // O br-utf8 não tem "lápide", "funeral" nem "doces". O segundo dicionário (VERO) cobre.
  const aceita = (w) => PALAVRAS[J.normalizar(w).length].validas[J.normalizar(w)];
  assert.strictEqual(aceita('lápide'), 'lápide');
  assert.strictEqual(aceita('lápides'), 'lápides');
  assert.ok(aceita('funeral'));
  assert.ok(aceita('doces'));
});
