# -*- coding: utf-8 -*-
"""Infográfico do Hormos — coordenadas fixas, desenhado à mão.

Mermaid foi tentado e descartado: o layout automático empilhou os frameworks
em coluna e jogou metade do grafo para fora da tela.

A primeira versão à mão ainda tinha travessias — a curva Plano→Risco cortava
a caixa de Evidência e o rótulo caía em cima dela. Aqui a Evidência foi para
a DIREITA, embaixo da Política: assim todas as setas correm para a esquerda
ou para cima, e nenhuma cruza caixa.

Uma ideia só: NADA AQUI É ISOLADO. A mesma evidência sustenta várias réguas,
e o ciclo fecha — plano com eficácia comprovada volta e derruba o risco.
"""
W, H = 1060, 580
AZUL, CIANO, VERDE, ROXO = '#2563EB', '#0891B2', '#059669', '#7C3AED'
TINTA, FRACO, LINHA = '#0F172A', '#64748B', '#CBD5E1'
F = "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif"
o = []; a = o.append

a(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" '
  f'font-family="{F}" role="img" aria-label="Como o Hormos se conecta: um grafo, não telas soltas">')
a('<title>Hormos — um grafo, não telas soltas</title>')
mk = lambda i, c: (f'<marker id="{i}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6.5" '
                   f'markerHeight="6.5" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{c}"/></marker>')
a('<defs>' + mk('s', FRACO) + mk('sv', VERDE) + mk('sa', AZUL) + '</defs>')
a(f'<rect width="{W}" height="{H}" fill="#FFFFFF"/>')

def caixa(x, y, w, h, txt, cor=TINTA, borda=LINHA, fundo='#FFFFFF', tam=13.5, peso=600, sub=None):
    a(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="9" fill="{fundo}" stroke="{borda}" stroke-width="1.5"/>')
    cy = y + h/2 + (0 if not sub else -6)
    a(f'<text x="{x+w/2}" y="{cy}" text-anchor="middle" dominant-baseline="middle" '
      f'font-size="{tam}" font-weight="{peso}" fill="{cor}">{txt}</text>')
    if sub:
        a(f'<text x="{x+w/2}" y="{cy+15}" text-anchor="middle" dominant-baseline="middle" '
          f'font-size="10" fill="{FRACO}">{sub}</text>')

def rot(x, y, t, cor=FRACO, tam=10, anc='middle', peso=600, esp='0'):
    a(f'<text x="{x}" y="{y}" text-anchor="{anc}" font-size="{tam}" font-weight="{peso}" '
      f'fill="{cor}" letter-spacing="{esp}">{t}</text>')

def seta(x1, y1, x2, y2, cor=FRACO, m='s', trac=False, lg=1.5):
    d = ' stroke-dasharray="5 3"' if trac else ''
    a(f'<path d="M{x1} {y1} L{x2} {y2}" stroke="{cor}" stroke-width="{lg}" '
      f'marker-end="url(#{m})" fill="none"{d}/>')

# ── Réguas ──────────────────────────────────────────────────────────────
a(f'<rect x="22" y="20" width="{W-44}" height="94" rx="12" fill="#2563EB08" stroke="{AZUL}33"/>')
rot(42, 45, 'AS RÉGUAS', AZUL, 10, 'start', 800, '.08em')
rot(142, 45, 'cada framework mede o MESMO SGSI, na sua própria natureza — sem número único somando coisas incomparáveis',
    FRACO, 10, 'start', 400)
def _subitens_igovtic():
    """Conta no catálogo em vez de cravar. Diagrama que afirma número tem de
    buscá-lo na fonte, senão vira PNG que mente depois da próxima revisão."""
    import sys, os
    sys.path.insert(0, os.environ.get('PORTAL', '/Users/sgd/projeto-hormos/hormos-portal'))
    import igovtic
    cat = igovtic.carregar(max(igovtic.ciclos_disponiveis()))
    return sum(1 for g in ('perguntas_tic', 'perguntas_negocio')
               for q in cat[g] for it in q['itens'] for _ in it['subitens'])

fw = [('ISO 27001', '93 controles'), ('CIS v8', '153 salvaguardas'), ('NIST CSF', '107 subcategorias'),
      ('COBIT', '41 objetivos'), ('ISO 42001', '38 controles'), ('LGPD', '20 artigos'),
      ('iGovTIC-JUD', f'{_subitens_igovtic()} subitens')]
lw, gap, lx = 132, 10, 42
for i, (nome, n) in enumerate(fw):
    d = nome.startswith('iGov')
    caixa(lx + i*(lw+gap), 60, lw, 40, nome, CIANO if d else AZUL,
          CIANO if d else f'{AZUL}55', f'{CIANO}14' if d else f'{AZUL}0A', 11.5, 700, sub=n)

a(f'<path d="M{W/2} 114 L{W/2} 146" stroke="{AZUL}" stroke-width="1.6" marker-end="url(#sa)" fill="none"/>')
rot(W/2+138, 136, 'todas leem a mesma base', AZUL, 10, 'middle', 700)

# ── O SGSI ──────────────────────────────────────────────────────────────
a(f'<rect x="22" y="154" width="{W-44}" height="266" rx="12" fill="#F8FAFC" stroke="{LINHA}"/>')
rot(42, 179, 'O SGSI', TINTA, 10, 'start', 800, '.08em')
rot(108, 179, 'um grafo — você nunca digita a mesma informação duas vezes', FRACO, 10, 'start', 400)

bw, bh, y1, y2 = 150, 50, 200, 318
cx = [42, 234, 426, 618, 810]

caixa(cx[0], y1, bw, bh, 'Contexto')
caixa(cx[1], y1, bw, bh, 'Ativo')
caixa(cx[2], y1, bw, bh, 'Risco')
caixa(cx[3], y1, bw, bh, 'Controle', sub='SOA')
caixa(cx[4], y1, bw, bh, 'Política')
caixa(cx[1], y2, bw, bh, 'Auditoria')
caixa(cx[2], y2, bw, bh, 'Evento / NC')
caixa(cx[3], y2, bw, bh, 'Plano de ação')
caixa(cx[4], y2, bw, bh, 'Evidência', VERDE, VERDE, f'{VERDE}12', 13.5, 700)

for i in range(3):                                    # Contexto→Ativo→Risco→Controle
    seta(cx[i]+bw, y1+bh/2, cx[i+1]-5, y1+bh/2)
seta(cx[4], y1+bh/2, cx[3]+bw+5, y1+bh/2)             # Política → Controle
rot(cx[4]-21, y1+bh/2-9, 'sustenta', FRACO, 9, 'middle', 500)
seta(cx[1]+bw, y2+bh/2, cx[2]-5, y2+bh/2)             # Auditoria → NC
seta(cx[2]+bw, y2+bh/2, cx[3]-5, y2+bh/2)             # NC → Plano
seta(cx[4], y2+bh/2, cx[3]+bw+5, y2+bh/2, VERDE, 'sv')# Evidência → Plano
# O vão entre Plano e Evidência tem 42px: o rótulo não cabe deitado ali e
# saía cortado pela caixa. Sobe para a linha de cima, onde há folga.
rot(cx[3]+bw+21, y2-7, 'comprova o plano', VERDE, 9, 'middle', 700)

# Evidência → Controle (sobe pela direita, sem cruzar nada)
a(f'<path d="M{cx[4]+bw-26} {y2} L{cx[4]+bw-26} {y1+bh+30} L{cx[3]+bw-26} {y1+bh+30} '
  f'L{cx[3]+bw-26} {y1+bh+5}" stroke="{VERDE}" stroke-width="1.8" fill="none" marker-end="url(#sv)"/>')
rot(cx[4]-6, y1+bh+24, 'comprova o controle', VERDE, 9.5, 'middle', 700)

# Plano → Risco: desce, corre por baixo e sobe. Não toca em nenhuma caixa.
yb = y2 + bh + 26
a(f'<path d="M{cx[3]+30} {y2+bh} L{cx[3]+30} {yb} L{cx[2]+36} {yb} L{cx[2]+36} {y1+bh+5}" '
  f'stroke="{VERDE}" stroke-width="1.8" fill="none" marker-end="url(#sv)"/>')
rot(cx[2]+bw+40, yb+14, 'eficácia comprovada derruba o risco residual', VERDE, 9.5, 'middle', 700)

# A tese: a mesma evidência sobe para as réguas, pela direita, sem cruzar nada.
a(f'<path d="M{cx[4]+bw} {y2+18} C {W-34} {y2+18}, {W-34} 180, {W-34} 128" '
  f'stroke="{VERDE}" stroke-width="2.4" fill="none" marker-end="url(#sv)"/>')
# A tarja ocupa só a coluna vazia da esquerda (até cx[1]); antes ela tinha
# 240px e cobria metade da caixa "Auditoria", que aparecia como "uditoria".
a(f'<rect x="{cx[0]}" y="{y2-2}" width="{cx[1]-cx[0]-22}" height="54" rx="9" '
  f'fill="#FFFFFF" stroke="{VERDE}55"/>')
_tx = cx[0] + (cx[1]-cx[0]-22)/2
rot(_tx, y2+18, 'a MESMA evidência', VERDE, 11.5, 'middle', 800)
rot(_tx, y2+34, 'serve a várias réguas', FRACO, 9.5, 'middle', 500)
rot(_tx, y2+47, 'de uma vez', FRACO, 9.5, 'middle', 500)

# ── Analista IA ─────────────────────────────────────────────────────────
a(f'<path d="M{W/2} 420 L{W/2} 434" stroke="{ROXO}" stroke-width="1.4" fill="none" stroke-dasharray="4 3"/>')
a(f'<rect x="22" y="436" width="{W-44}" height="62" rx="12" fill="#7C3AED0C" stroke="{ROXO}44"/>')
rot(42, 461, 'ANALISTA IA', ROXO, 10, 'start', 800, '.08em')
rot(158, 461, 'roda na sua máquina — nenhum dado do SGSI sai da rede, inclusive o que a IA processa', FRACO, 10, 'start', 400)
rot(42, 483, 'Lê política e evidência · correlaciona com o controle · redige o parecer · diz o que já dá para declarar — e nunca inventa fato: tudo sai do que está registrado.',
    TINTA, 10.5, 'start', 400)

rot(42, 528, 'ὅρμος — o ancoradouro abrigado no meio da viagem, e o colar: contas presas num mesmo fio.', FRACO, 10, 'start', 400)
rot(W-42, 528, 'hormosgrc.github.io', FRACO, 10, 'end', 600)
a('</svg>')
import pathlib
pathlib.Path('/tmp/ico/hormos-grafo.svg').write_text('\n'.join(o), encoding='utf-8')
print('  SVG regerado')
