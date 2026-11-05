// Tela do jogo: grade, teclado, janelas e dados salvos no navegador.
(function () {
  const { TAMANHO, TENTATIVAS, normalizar, avaliar, estadoTeclado, numeroDoDia, palavraDoDia, textoCompartilhar } = window.Jogo;
  const $ = (id) => document.getElementById(id);
  const TEMPO_VIRAR = 280; // ms entre uma letra e a próxima na hora de revelar
  const FILEIRAS = ['QWERTYUIOP', 'ASDFGHJKL', '<ZXCVBNM>'];

  let modo = localStorage.getItem('palpite:modo') || 'diario';
  let jogo; // { resposta, numero?, palpites: [], fim: bool, venceu: bool }
  let letras = Array(TAMANHO).fill('');
  let cursor = 0;
  let ocupado = false; // true enquanto a animação roda

  // ---------- dados salvos ----------
  const ler = (k, padrao) => {
    try { return JSON.parse(localStorage.getItem(k)) ?? padrao; } catch { return padrao; }
  };
  const gravar = (k, v) => localStorage.setItem(k, JSON.stringify(v));
  const statsVazias = () => ({ jogos: 0, vitorias: 0, sequencia: 0, melhor: 0, dist: Array(TENTATIVAS).fill(0) });

  function carregarJogo() {
    if (modo === 'diario') {
      const numero = numeroDoDia(new Date());
      const salvo = ler('palpite:diario', null);
      if (salvo && salvo.numero === numero) return salvo;
      return { numero, resposta: palavraDoDia(RESPOSTAS, numero), palpites: [], fim: false, venceu: false };
    }
    const salvo = ler('palpite:livre', null);
    if (salvo && !salvo.fim) return salvo;
    return novoLivre();
  }
  function novoLivre() {
    const resposta = RESPOSTAS[Math.floor(Math.random() * RESPOSTAS.length)];
    return { resposta, palpites: [], fim: false, venceu: false };
  }
  const salvarJogo = () => gravar('palpite:' + modo, jogo);

  function registrarFim() {
    const k = 'palpite:stats:' + modo;
    const s = ler(k, statsVazias());
    s.jogos++;
    if (jogo.venceu) {
      s.vitorias++;
      s.sequencia++;
      s.melhor = Math.max(s.melhor, s.sequencia);
      s.dist[jogo.palpites.length - 1]++;
    } else {
      s.sequencia = 0;
    }
    gravar(k, s);
  }

  // ---------- desenho ----------
  const chave = () => normalizar(jogo.resposta);
  const avaliacoes = () => jogo.palpites.map((p) => avaliar(p, chave()));
  // Mostra a palavra com acento, se existir: "NIVEL" -> "NÍVEL".
  const comAcento = (k) => (VALIDAS[k] || k).toUpperCase();

  function montarGrade() {
    const grade = $('grade');
    grade.innerHTML = '';
    const avs = avaliacoes();
    for (let i = 0; i < TENTATIVAS; i++) {
      const linha = document.createElement('div');
      linha.className = 'linha';
      for (let j = 0; j < TAMANHO; j++) {
        const t = document.createElement('div');
        t.className = 'ladrilho';
        t.dataset.col = j;
        linha.appendChild(t);
      }
      if (i < jogo.palpites.length) {
        const txt = comAcento(jogo.palpites[i]);
        [...linha.children].forEach((t, j) => {
          t.textContent = txt[j];
          t.classList.add(avs[i][j]);
        });
      } else if (i === jogo.palpites.length && !jogo.fim) {
        linha.classList.add('atual');
      } else {
        linha.classList.add('futura');
      }
      grade.appendChild(linha);
    }
    desenharAtual();
  }

  function linhaAtual() {
    return $('grade').children[jogo.palpites.length];
  }

  function desenharAtual() {
    if (jogo.fim) return;
    const linha = linhaAtual();
    [...linha.children].forEach((t, j) => {
      t.textContent = letras[j];
      t.classList.toggle('cursor', j === cursor);
    });
  }

  function montarTeclado() {
    const tec = $('teclado');
    tec.innerHTML = '';
    for (const f of FILEIRAS) {
      const fil = document.createElement('div');
      fil.className = 'fileira';
      for (const c of f) {
        const b = document.createElement('button');
        b.className = 'tecla';
        if (c === '<') {
          b.textContent = '⌫';
          b.dataset.tecla = 'Backspace';
          b.setAttribute('aria-label', 'Apagar');
          b.classList.add('larga');
        } else if (c === '>') {
          b.textContent = 'ENVIAR';
          b.dataset.tecla = 'Enter';
          b.classList.add('larga', 'enviar');
        } else {
          b.textContent = c;
          b.dataset.tecla = c;
        }
        fil.appendChild(b);
      }
      tec.appendChild(fil);
    }
    pintarTeclado();
  }

  function pintarTeclado() {
    const estado = estadoTeclado(jogo.palpites, avaliacoes());
    document.querySelectorAll('.tecla').forEach((b) => {
      const l = b.dataset.tecla;
      b.classList.remove('certa', 'lugar', 'errada');
      if (estado[l]) b.classList.add(estado[l]);
    });
  }

  function desenharModo() {
    document.querySelectorAll('.modo').forEach((b) => {
      const ativo = b.dataset.modo === modo;
      b.classList.toggle('ativo', ativo);
      b.setAttribute('aria-selected', ativo);
    });
    $('subtitulo').textContent = modo === 'diario' ? `Desafio nº ${jogo.numero}` : 'Jogue quantas vezes quiser';
  }

  let timerAviso;
  function avisar(msg, ms = 1800, erro = false) {
    const a = $('aviso');
    a.textContent = msg;
    a.classList.toggle('erro', erro);
    a.classList.add('mostrar');
    clearTimeout(timerAviso);
    timerAviso = setTimeout(() => a.classList.remove('mostrar'), ms);
  }

  // ---------- jogada ----------
  function limparErro() {
    if (!jogo.fim) linhaAtual().classList.remove('invalida');
  }

  function digitar(l) {
    if (jogo.fim || ocupado) return;
    limparErro();
    letras[cursor] = l;
    const t = linhaAtual().children[cursor];
    t.classList.remove('cheio');
    void t.offsetWidth;
    t.classList.add('cheio');
    // pula para o próximo quadrado vazio à direita; se não houver, avança um
    let prox = letras.findIndex((x, i) => i > cursor && !x);
    cursor = prox === -1 ? Math.min(cursor + 1, TAMANHO - 1) : prox;
    desenharAtual();
  }

  function apagar() {
    if (jogo.fim || ocupado) return;
    limparErro();
    if (letras[cursor]) letras[cursor] = '';
    else if (cursor > 0) { cursor--; letras[cursor] = ''; }
    desenharAtual();
  }

  function mover(d) {
    if (jogo.fim || ocupado) return;
    cursor = Math.max(0, Math.min(TAMANHO - 1, cursor + d));
    desenharAtual();
  }

  function tremer(msg) {
    avisar(msg, 2400, true);
    const linha = linhaAtual();
    linha.classList.remove('tremer', 'invalida');
    void linha.offsetWidth;
    linha.classList.add('tremer', 'invalida');
  }

  function enviar() {
    if (jogo.fim || ocupado) return;
    if (letras.some((x) => !x)) return tremer('Só palavras com 5 letras');
    const palpite = letras.join('');
    if (!VALIDAS[palpite]) return tremer('Essa palavra não está no dicionário');

    ocupado = true;
    const linha = linhaAtual();
    const av = avaliar(palpite, chave());
    const txt = comAcento(palpite);
    linha.classList.remove('atual');
    [...linha.children].forEach((t, j) => {
      t.classList.remove('cursor', 'cheio');
      setTimeout(() => {
        t.classList.add('virar');
        setTimeout(() => {
          t.textContent = txt[j];
          t.classList.add(av[j]);
        }, 250);
      }, j * TEMPO_VIRAR);
    });

    jogo.palpites.push(palpite);
    const venceu = palpite === chave();
    if (venceu || jogo.palpites.length === TENTATIVAS) {
      jogo.fim = true;
      jogo.venceu = venceu;
      registrarFim();
    }
    salvarJogo();

    setTimeout(() => {
      ocupado = false;
      letras = Array(TAMANHO).fill('');
      cursor = 0;
      pintarTeclado();
      if (jogo.fim) {
        if (venceu) {
          linha.classList.add('venceu');
          [...linha.children].forEach((t, j) => (t.style.animationDelay = j * 90 + 'ms'));
          const frases = ['Genial!', 'Incrível!', 'Muito bem!', 'Boa!', 'Ufa, deu!', 'No limite!'];
          avisar(frases[jogo.palpites.length - 1], 1800);
        } else {
          avisar('A palavra era ' + comAcento(chave()), 2600);
        }
        setTimeout(abrirFim, venceu ? 1300 : 1800);
      } else {
        const prox = linhaAtual();
        prox.classList.remove('futura');
        prox.classList.add('atual');
        desenharAtual();
      }
    }, TAMANHO * TEMPO_VIRAR + 300);
  }

  // ---------- janelas ----------
  function abrirFim() {
    $('fim-titulo').textContent = jogo.venceu ? 'Você acertou! 🎉' : 'Não foi dessa vez';
    $('fim-palavra').innerHTML = 'A palavra era <b></b>';
    $('fim-palavra').querySelector('b').textContent = jogo.resposta;
    $('fim-palavra').hidden = !jogo.fim;
    $('fim-modo').textContent = modo === 'diario' ? 'desafio do dia' : 'modo livre';
    if (!jogo.fim) $('fim-titulo').textContent = 'Estatísticas';

    const s = ler('palpite:stats:' + modo, statsVazias());
    const pct = s.jogos ? Math.round((100 * s.vitorias) / s.jogos) : 0;
    $('fim-numeros').innerHTML = [
      [s.jogos, 'jogos'], [pct + '%', 'vitórias'], [s.sequencia, 'sequência'], [s.melhor, 'melhor seq.'],
    ].map(([n, r]) => `<div><b>${n}</b><span>${r}</span></div>`).join('');

    const max = Math.max(1, ...s.dist);
    $('fim-dist').innerHTML = s.dist.map((n, i) => {
      const destaque = jogo.fim && jogo.venceu && jogo.palpites.length === i + 1 ? ' destaque' : '';
      return `<div class="barra${destaque}"><span>${i + 1}</span><div style="width:${Math.max(8, (100 * n) / max)}%">${n}</div></div>`;
    }).join('');

    $('btn-compartilhar').hidden = !jogo.fim;
    const prox = $('btn-proxima');
    if (modo === 'livre') {
      prox.hidden = !jogo.fim;
      prox.textContent = 'Jogar de novo';
    } else {
      prox.hidden = !jogo.fim;
      prox.textContent = 'Ir para o modo livre';
    }
    atualizarContagem();
    $('dlg-fim').showModal();
  }

  let timerContagem;
  function atualizarContagem() {
    clearInterval(timerContagem);
    const el = $('fim-contagem');
    if (modo !== 'diario' || !jogo.fim) { el.textContent = ''; return; }
    const tic = () => {
      const agora = new Date();
      const amanha = new Date(agora.getFullYear(), agora.getMonth(), agora.getDate() + 1);
      const s = Math.floor((amanha - agora) / 1000);
      const p = (n) => String(n).padStart(2, '0');
      el.textContent = `Nova palavra em ${p(Math.floor(s / 3600))}:${p(Math.floor((s % 3600) / 60))}:${p(s % 60)}`;
    };
    tic();
    timerContagem = setInterval(tic, 1000);
  }

  async function compartilhar() {
    const titulo = modo === 'diario' ? `Palpite #${jogo.numero}` : 'Palpite (modo livre)';
    const texto = textoCompartilhar(titulo, avaliacoes(), jogo.venceu);
    try {
      await navigator.clipboard.writeText(texto);
      avisar('Resultado copiado');
    } catch {
      avisar('Não deu para copiar');
    }
  }

  function trocarModo(m) {
    if (ocupado || m === modo) return;
    modo = m;
    localStorage.setItem('palpite:modo', m);
    iniciar();
  }

  function iniciar() {
    jogo = carregarJogo();
    salvarJogo();
    letras = Array(TAMANHO).fill('');
    cursor = 0;
    desenharModo();
    montarGrade();
    montarTeclado();
    if (jogo.fim) setTimeout(abrirFim, 300);
  }

  // ---------- eventos ----------
  function tecla(k) {
    if (k === 'Enter') enviar();
    else if (k === 'Backspace') apagar();
    else if (k === 'ArrowLeft') mover(-1);
    else if (k === 'ArrowRight') mover(1);
    else {
      const l = normalizar(k);
      if (/^[A-Z]$/.test(l)) digitar(l);
    }
  }

  document.addEventListener('keydown', (e) => {
    if (e.metaKey || e.ctrlKey || e.altKey) return;
    if (document.querySelector('dialog[open]')) return;
    if (e.key.length === 1 || ['Enter', 'Backspace', 'ArrowLeft', 'ArrowRight'].includes(e.key)) {
      e.preventDefault();
      tecla(e.key);
    }
  });

  $('teclado').addEventListener('click', (e) => {
    const b = e.target.closest('.tecla');
    if (b) { tecla(b.dataset.tecla); b.blur(); }
  });

  $('grade').addEventListener('click', (e) => {
    const t = e.target.closest('.linha.atual .ladrilho');
    if (!t || ocupado) return;
    cursor = Number(t.dataset.col);
    desenharAtual();
  });

  document.querySelectorAll('.modo').forEach((b) => b.addEventListener('click', () => trocarModo(b.dataset.modo)));
  $('btn-ajuda').addEventListener('click', () => $('dlg-ajuda').showModal());
  $('btn-stats').addEventListener('click', abrirFim);
  $('btn-compartilhar').addEventListener('click', compartilhar);
  $('btn-proxima').addEventListener('click', () => {
    $('dlg-fim').close();
    if (modo === 'livre') {
      jogo = novoLivre();
      gravar('palpite:livre', jogo);
      iniciar();
    } else {
      trocarModo('livre');
    }
  });
  document.querySelectorAll('dialog').forEach((d) => {
    d.addEventListener('click', (e) => {
      if (e.target === d || e.target.closest('[data-fechar]')) d.close();
    });
  });

  iniciar();
  if (!localStorage.getItem('palpite:viu-ajuda')) {
    localStorage.setItem('palpite:viu-ajuda', '1');
    $('dlg-ajuda').showModal();
  }
})();
