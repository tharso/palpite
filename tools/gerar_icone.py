"""Desenha o ícone do app (PNG 1024x1024, sem transparência) só com a biblioteca padrão.
Uso: python3 tools/gerar_icone.py ios/Palpite/Assets.xcassets/AppIcon.appiconset/icone.png
"""
import math, struct, sys, zlib

N = 1024
def hexcor(h): return ((h >> 16) & 255, (h >> 8) & 255, h & 255)
TOPO, BASE = hexcor(0x2B2456), hexcor(0x17152B)
C, L, E = hexcor(0x22A06B), hexcor(0xE3A92B), hexcor(0x67637F)
GRADE = [[E, L, E], [C, E, L], [C, C, C]]  # uma partida sendo resolvida
LADO, VAO, RAIO = 236, 30, 46
INICIO = (N - (3 * LADO + 2 * VAO)) // 2

def dist_retangulo(px, py, cx, cy, meio, r):
    qx, qy = abs(px - cx) - (meio - r), abs(py - cy) - (meio - r)
    fora = math.hypot(max(qx, 0), max(qy, 0))
    return fora + min(max(qx, qy), 0) - r

linhas = []
for y in range(N):
    t = y / (N - 1)
    fundo = tuple(round(TOPO[i] + (BASE[i] - TOPO[i]) * t) for i in range(3))
    linha = bytearray(b"\x00")  # filtro "None" do PNG
    for x in range(N):
        cor = fundo
        col, lin = (x - INICIO) // (LADO + VAO), (y - INICIO) // (LADO + VAO)
        if 0 <= col < 3 and 0 <= lin < 3:
            cx = INICIO + col * (LADO + VAO) + LADO / 2
            cy = INICIO + lin * (LADO + VAO) + LADO / 2
            a = min(1.0, max(0.0, 0.5 - dist_retangulo(x + 0.5, y + 0.5, cx, cy, LADO / 2, RAIO)))
            if a > 0:
                t2 = GRADE[lin][col]
                cor = tuple(round(fundo[i] * (1 - a) + t2[i] * a) for i in range(3))
        linha += bytes(cor)
    linhas.append(bytes(linha))

def bloco(tipo, dados):
    return struct.pack(">I", len(dados)) + tipo + dados + struct.pack(">I", zlib.crc32(tipo + dados) & 0xFFFFFFFF)

png = b"\x89PNG\r\n\x1a\n" + bloco(b"IHDR", struct.pack(">IIBBBBB", N, N, 8, 2, 0, 0, 0))
png += bloco(b"IDAT", zlib.compress(b"".join(linhas), 9)) + bloco(b"IEND", b"")
open(sys.argv[1], "wb").write(png)
print("ok", sys.argv[1], len(png), "bytes")
