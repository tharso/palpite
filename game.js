// Regras do jogo, sem nada de tela. Roda no navegador e no Node (para os testes).
(function (root) {
  const TAMANHO = 5;
  const TENTATIVAS = 6;
  const INICIO = Date.UTC(2026, 0, 1); // dia 1 do desafio diário

  // Tira acentos e cedilha e põe em maiúsculas: "Ação" -> "ACAO".
  function normalizar(palavra) {
    return palavra.normalize('NFD').replace(/[̀-ͯ]/g, '').toUpperCase();
  }

  // Compara palpite e resposta (já normalizados). Devolve, por letra:
  // 'certa' (verde), 'lugar' (amarela) ou 'errada' (cinza).
  // Letras repetidas: cada letra da resposta só "paga" uma pista.
  function avaliar(palpite, resposta) {
    const res = Array(palpite.length).fill('errada');
    const sobra = {};
    for (let i = 0; i < resposta.length; i++) {
      if (palpite[i] === resposta[i]) res[i] = 'certa';
      else sobra[resposta[i]] = (sobra[resposta[i]] || 0) + 1;
    }
    for (let i = 0; i < palpite.length; i++) {
      if (res[i] === 'certa') continue;
      const l = palpite[i];
      if (sobra[l] > 0) {
        res[i] = 'lugar';
        sobra[l]--;
      }
    }
    return res;
  }

  // Melhor pista de cada letra do teclado: certa > lugar > errada.
  function estadoTeclado(palpites, avaliacoes) {
    const peso = { errada: 1, lugar: 2, certa: 3 };
    const teclas = {};
    palpites.forEach((p, i) => {
      for (let j = 0; j < p.length; j++) {
        const atual = teclas[p[j]];
        const nova = avaliacoes[i][j];
        if (!atual || peso[nova] > peso[atual]) teclas[p[j]] = nova;
      }
    });
    return teclas;
  }

  // Número do desafio do dia (1, 2, 3...) pela data local.
  function numeroDoDia(data) {
    const hoje = Date.UTC(data.getFullYear(), data.getMonth(), data.getDate());
    return Math.floor((hoje - INICIO) / 86400000) + 1;
  }

  // Embaralha a lista sempre do mesmo jeito (semente fixa), para o desafio
  // diário não seguir a ordem de frequência.
  function embaralhar(lista, semente) {
    const a = lista.slice();
    let s = semente >>> 0;
    const rand = () => {
      s = (s + 0x6d2b79f5) >>> 0;
      let t = s;
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(rand() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }

  function palavraDoDia(respostas, numero) {
    const ordem = embaralhar(respostas, 20260101);
    const i = (((numero - 1) % ordem.length) + ordem.length) % ordem.length;
    return ordem[i];
  }

  // Texto para compartilhar o resultado com quadradinhos coloridos.
  function textoCompartilhar(titulo, avaliacoes, venceu) {
    const cor = { certa: '🟩', lugar: '🟨', errada: '⬛' };
    const placar = venceu ? `${avaliacoes.length}/${TENTATIVAS}` : `X/${TENTATIVAS}`;
    const linhas = avaliacoes.map((a) => a.map((x) => cor[x]).join(''));
    return `${titulo} ${placar}\n\n${linhas.join('\n')}`;
  }

  const api = { TAMANHO, TENTATIVAS, normalizar, avaliar, estadoTeclado, numeroDoDia, palavraDoDia, embaralhar, textoCompartilhar };
  if (typeof module !== 'undefined') module.exports = api;
  else root.Jogo = api;
})(typeof window !== 'undefined' ? window : globalThis);
