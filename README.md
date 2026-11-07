# Palpite

Jogo de adivinhar uma palavra em português, em até 6 tentativas. A palavra pode ter 4, 5, 6 ou 7 letras: o jogador escolhe.

- **Verde:** a letra está na palavra e na posição certa.
- **Amarela:** a letra está na palavra, mas em outra posição.
- **Cinza:** a letra não está na palavra.

Tem dois modos. O **desafio do dia** dá uma palavra por dia em cada tamanho, igual para todo mundo. O **modo livre** sorteia uma palavra nova a cada partida.

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

O `palavras.js` tem, para cada tamanho, duas listas:

- `validas`: palavras que o jogo aceita como palpite (3.680 de 4 letras, 11.879 de 5, 25.505 de 6, 42.852 de 7).
- `respostas`: palavras comuns que podem virar a palavra secreta (de 569 a 1.432 por tamanho).

A lista de respostas de 5 letras não pode mudar: ela define o desafio do dia de quem já joga. Os testes conferem isso.

As palavras aceitas vêm de dois dicionários. O do IME-USP tem buracos (não tem "lápide", por exemplo), e o VERO cobre. As palavras do VERO só viram palpite aceito, nunca palavra secreta.

Para gerar de novo, baixe as três fontes e rode:

```bash
python3 tools/build_words.py br-utf8.txt pt_br_50k.txt palavras.js ios/Palpite/palavras.json palavras.txt
```

Fontes:

- Dicionário `br-utf8.txt`, do IME-USP: https://www.ime.usp.br/~pf/dicios/
- Lista de frequência `pt_br_50k.txt`, do projeto FrequencyWords, de Hermit Dave (CC-BY-SA 4.0): https://github.com/hermitdave/FrequencyWords
- Dicionário `palavras.txt`, do VERO (LibreOffice), no projeto pythonprobr/palavras (MPL-2.0): https://github.com/pythonprobr/palavras

## App para iPhone (pasta `ios/`)

App nativo em SwiftUI, com as mesmas regras e a mesma palavra do dia do site.

| Pasta | O que tem |
|---|---|
| `ios/PalpiteCore/` | Regras do jogo em Swift (pacote) e testes |
| `ios/Palpite/` | Telas do app, ícone e `palavras.json` |
| `ios/Palpite.xcodeproj` | Projeto do Xcode |

Abrir no Xcode: `open ios/Palpite.xcodeproj`.

Testar as regras sem o Xcode:

```bash
cd ios/PalpiteCore && swift test
```

O `ios/Palpite/palavras.json` sai do mesmo comando que gera o `palavras.js`.

O ícone é gerado por `python3 tools/gerar_icone.py ios/Palpite/Assets.xcassets/AppIcon.appiconset/icone.png`.

A página de privacidade e suporte, que a App Store exige, fica em `privacidade.html` (palpite.tharso.com/privacidade).

## Próximos passos

- Publicar o app na App Store.
