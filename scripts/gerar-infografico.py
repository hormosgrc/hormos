# -*- coding: utf-8 -*-
"""Infográfico do Hormos — a cadeia REAL do SGSI.

A primeira versão errava o modelo, não o layout: começava em "Contexto →
Ativo", quando o contexto é DO ativo; e deixava a evidência flutuando com
setas subindo sem ordem, dando a impressão de que ela só servia ao iGovTIC.

A cadeia correta, como o produto de fato funciona:
  o ATIVO tem seu contexto → dele se mede o RISCO → do risco nascem CONTROLE
  e POLÍTICA → auditoria e verificação apuram EVENTO / NÃO CONFORMIDADE →
  que gera PLANO DE AÇÃO → e a EVIDÊNCIA é o que prova que o plano deu certo
  E que controle e política estão funcionando.

Tudo preso ao mesmo ativo. Por isso é grafo, e não lista de telas.
"""
W, H = 1120, 540
AZUL, CIANO, VERDE, ROXO = '#2563EB', '#0891B2', '#059669', '#7C3AED'
TINTA, FRACO, LINHA = '#0F172A', '#64748B', '#CBD5E1'
F = "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif"
o = []; a = o.append
a(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" '
  f'font-family="{F}" role="img" aria-label="A cadeia do SGSI no Hormos">')
a('<title>Hormos — a cadeia do SGSI</title>')
mk = lambda i, c: (f'<marker id="{i}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6.5" '
                   f'markerHeight="6.5" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{c}"/></marker>')
a('<defs>' + mk('s', '#475569') + mk('sv', VERDE) + mk('sa', AZUL) + '</defs>')
a(f'<rect width="{W}" height="{H}" fill="#FFFFFF"/>')

def cx_(x, y, w, h, t, sub=None, cor=TINTA, bd=LINHA, bg='#FFFFFF', tam=13.5, pz=700):
    a(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="10" fill="{bg}" stroke="{bd}" stroke-width="1.6"/>')
    cy = y + h/2 + (-7 if sub else 0)
    a(f'<text x="{x+w/2}" y="{cy}" text-anchor="middle" dominant-baseline="middle" '
      f'font-size="{tam}" font-weight="{pz}" fill="{cor}">{t}</text>')
    if sub:
        a(f'<text x="{x+w/2}" y="{cy+16}" text-anchor="middle" dominant-baseline="middle" '
          f'font-size="9.5" fill="{FRACO}">{sub}</text>')

def rot(x, y, t, cor=FRACO, tam=10, anc='middle', pz=600, esp='0'):
    a(f'<text x="{x}" y="{y}" text-anchor="{anc}" font-size="{tam}" font-weight="{pz}" '
      f'fill="{cor}" letter-spacing="{esp}">{t}</text>')

def seta(x1, y1, x2, y2, cor='#475569', m='s', lg=1.6, trac=False):
    d = ' stroke-dasharray="5 3"' if trac else ''
    a(f'<path d="M{x1} {y1} L{x2} {y2}" stroke="{cor}" stroke-width="{lg}" '
      f'marker-end="url(#{m})" fill="none"{d}/>')

def _n_igovtic():
    import sys, os
    sys.path.insert(0, os.environ.get('PORTAL', '/Users/sgd/projeto-hormos/hormos-portal'))
    import igovtic
    c = igovtic.carregar(max(igovtic.ciclos_disponiveis()))
    return sum(1 for g in ('perguntas_tic', 'perguntas_negocio')
               for q in c[g] for it in q['itens'] for _ in it['subitens'])

# ── Réguas ──────────────────────────────────────────────────────────────
a(f'<rect x="22" y="20" width="{W-44}" height="92" rx="12" fill="#2563EB08" stroke="{AZUL}33"/>')
rot(42, 44, 'AS RÉGUAS', AZUL, 10, 'start', 800, '.08em')
rot(144, 44, 'cada framework lê a MESMA cadeia e a mede na sua própria natureza — nunca um número único somando coisas incomparáveis',
    FRACO, 10, 'start', 400)
fw = [('ISO 27001','93 controles'),('CIS v8','153 salvaguardas'),('NIST CSF','107 subcategorias'),
      ('COBIT','41 objetivos'),('ISO 42001','38 controles'),('LGPD','20 artigos'),
      ('iGovTIC-JUD', f'{_n_igovtic()} subitens')]
lw, gp, lx = 140, 10, 42
for i,(n,d) in enumerate(fw):
    dest = n.startswith('iGov')
    cx_(lx+i*(lw+gp), 58, lw, 40, n, d, CIANO if dest else AZUL,
        CIANO if dest else f'{AZUL}55', f'{CIANO}14' if dest else f'{AZUL}0A', 11.5, 700)

# ── A cadeia ────────────────────────────────────────────────────────────
a(f'<rect x="22" y="160" width="{W-44}" height="232" rx="12" fill="#F8FAFC" stroke="{LINHA}"/>')
rot(42, 184, 'A CADEIA', TINTA, 10, 'start', 800, '.08em')
rot(124, 184, 'tudo preso ao mesmo ativo — por isso é um grafo, e não uma lista de telas', FRACO, 10, 'start', 400)

bw, bh, y = 148, 54, 206
gx = 16
xs = [42 + i*(bw+gx) for i in range(6)]
cx_(xs[0], y, bw, bh, 'ATIVO', 'e o contexto dele')
cx_(xs[1], y, bw, bh, 'RISCO', 'medido no ativo')
cx_(xs[2], y, bw, bh, 'CONTROLE', 'e POLÍTICA que o sustenta')
cx_(xs[3], y, bw, bh, 'EVENTO / NC', 'o que falhou')
cx_(xs[4], y, bw, bh, 'PLANO DE AÇÃO', 'o que vai ser feito')
cx_(xs[5], y, bw, bh, 'EVIDÊNCIA', 'a prova', VERDE, VERDE, f'{VERDE}12')

for i in range(5):
    seta(xs[i]+bw, y+bh/2, xs[i+1]-6, y+bh/2)
rot(xs[0]+bw+gx/2, y-8, 'expõe', FRACO, 9, 'middle', 500)
rot(xs[1]+bw+gx/2, y-8, 'trata', FRACO, 9, 'middle', 500)
rot(xs[2]+bw+gx/2, y-8, 'falha', FRACO, 9, 'middle', 500)
rot(xs[3]+bw+gx/2, y-8, 'gera', FRACO, 9, 'middle', 500)
rot(xs[4]+bw+gx/2, y-8, 'produz', FRACO, 9, 'middle', 500)

# auditoria e verificação alimentam o Evento/NC, por baixo
ya = y + bh + 28
cx_(xs[3]-22, ya, bw+44, 40, 'auditoria · verificação · monitoramento', None, FRACO, LINHA, '#FFFFFF', 10.5, 600)
seta(xs[3]+bw/2, ya, xs[3]+bw/2, y+bh+6)
rot(xs[3]+bw+56, ya+24, 'é assim que a falha aparece', FRACO, 9, 'start', 500)

# A evidência volta e VALIDA o controle e a política. É o laço que fecha.
yv = y + bh + 92
a(f'<path d="M{xs[5]+bw/2} {y+bh} L{xs[5]+bw/2} {yv} L{xs[2]+bw/2} {yv} L{xs[2]+bw/2} {y+bh+6}" '
  f'stroke="{VERDE}" stroke-width="2" fill="none" marker-end="url(#sv)"/>')
rot((xs[2]+xs[5])/2+bw/2, yv+16, 'a evidência prova que o plano deu certo — e valida que o controle e a política funcionam',
    VERDE, 10, 'middle', 700)

# A mesma evidência sobe para TODAS as réguas: sai do centro da faixa.
a(f'<path d="M{xs[5]+bw/2} {y} C {xs[5]+bw/2} 150, {W/2} 150, {W/2} 116" '
  f'stroke="{VERDE}" stroke-width="2.4" fill="none" marker-end="url(#sv)"/>')
rot(400, 142, 'a MESMA evidência comprova para TODAS as réguas — você anexa uma vez', VERDE, 10.5, 'middle', 800)

# ── Analista IA ─────────────────────────────────────────────────────────
a(f'<path d="M{W/2} 392 L{W/2} 406" stroke="{ROXO}" stroke-width="1.4" fill="none" stroke-dasharray="4 3"/>')
a(f'<rect x="22" y="408" width="{W-44}" height="62" rx="12" fill="#7C3AED0C" stroke="{ROXO}44"/>')
rot(42, 433, 'ANALISTA IA', ROXO, 10, 'start', 800, '.08em')
rot(160, 433, 'roda na sua máquina — nenhum dado do SGSI sai da rede, inclusive o que a IA processa', FRACO, 10, 'start', 400)
rot(42, 455, 'Lê a política e a evidência · correlaciona com o controle · redige o parecer · diz o que já dá para declarar — e nunca inventa fato: tudo sai do que está registrado.',
    TINTA, 10.5, 'start', 400)
rot(42, 500, 'ὅρμος — o ancoradouro abrigado no meio da viagem, e o colar: contas presas num mesmo fio.', FRACO, 10, 'start', 400)
rot(W-42, 500, 'hormosgrc.github.io', FRACO, 10, 'end', 600)
a('</svg>')
import pathlib
pathlib.Path('/tmp/ico/hormos-grafo.svg').write_text('\n'.join(o), encoding='utf-8')
print('  SVG regerado pela cadeia correta')
