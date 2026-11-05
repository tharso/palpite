# Palpite

Jogo de adivinhar uma palavra de 5 letras em português, em até 6 tentativas.

- **Verde:** a letra está na palavra e na posição certa.
- **Amarela:** a letra está na palavra, mas em outra posição.
- **Cinza:** a letra não está na palavra.

Tem dois modos. O **desafio do dia** dá uma palavra por dia, igual para todo mundo. O **modo livre** sorteia uma palavra nova a cada partida.

## Rodar no computador

O jogo é só HTML, CSS e JavaScript. Não precisa instalar nada.

```bash
python3 -m http.server 4747
```

Depois abra http://localhost:4747.

## Testes

```bash
node --test tests/
```

## Arquivos

| Arquivo | O que faz |
|---|---|
| `index.html` | Página do jogo |
| `style.css` | Visual |
| `game.js` | Regras: cores das letras, palavra do dia, texto para compartilhar. Não mexe na tela. |
| `app.js` | Tela: grade, teclado, janelas e dados salvos no navegador (`localStorage`) |
| `palavras.js` | Lista de palavras. Arquivo gerado, não editar à mão. |
| `tools/build_words.py` | Gera o `palavras.js` |

## Lista de palavras

O `palavras.js` tem duas listas:

- `VALIDAS`: cerca de 5.350 palavras de 5 letras que o jogo aceita como palpite.
- `RESPOSTAS`: cerca de 1.200 palavras comuns que podem virar a palavra secreta.

Para gerar de novo, baixe as duas fontes e rode:

```bash
python3 tools/build_words.py br-utf8.txt pt_br_50k.txt palavras.js
```

Fontes:

- Dicionário `br-utf8.txt`, do IME-USP: https://www.ime.usp.br/~pf/dicios/
- Lista de frequência `pt_br_50k.txt`, do projeto FrequencyWords, de Hermit Dave (CC-BY-SA 4.0): https://github.com/hermitdave/FrequencyWords

## Próximos passos

- Versão 2: app para iOS.
- Modos com 4, 6 e 7 letras.
