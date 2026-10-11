# -*- coding: utf-8 -*-
"""Infográfico do Hormos — "Da estratégia à evidência".

A COMPOSIÇÃO é do usuário (arte feita no Designer). Esta é a versão vetorial
dela, e existe por três motivos:

  · o original é PNG de 1536x1024 — macio em tela retina, e o texto é raster;
  · duas cláusulas estavam trocadas, e num produto de conformidade citar
    cláusula errada no README público é erro que o comprador nota:
      10.1 é MELHORIA CONTÍNUA (o laço de baixo), não incidente;
      10.2 é NÃO CONFORMIDADE E AÇÃO CORRETIVA — é ela nas etapas 7 e 8.
    Conferidas uma a uma contra a tabela `soa` do próprio produto.
  · os números saem do catálogo, então o desenho não envelhece sozinho.
"""
import sys, os
sys.path.insert(0, os.environ.get('PORTAL', '/Users/sgd/projeto-hormos/hormos-portal'))

W, H = 1536, 910
ESCURO, TINTA, FRACO = '#1E293B', '#0F172A', '#64748B'
BORDA, FUNDO = '#E2E8F0', '#F8FAFC'
F = "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,sans-serif"
o = []; a = o.append

def txt(x, y, t, tam=12, cor=TINTA, pz=400, anc='start', esp='0', it=False):
    i = ' font-style="italic"' if it else ''
    a(f'<text x="{x}" y="{y}" font-size="{tam}" font-weight="{pz}" fill="{cor}" '
      f'text-anchor="{anc}" letter-spacing="{esp}"{i}>{t}</text>')

def cxa(x, y, w, h, r=10, fill='#FFFFFF', bd=BORDA, lg=1.3):
    a(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" stroke="{bd}" stroke-width="{lg}"/>')


ICO = {
 'pessoas': '<circle cx="7" cy="7" r="3.2"/><circle cx="15.5" cy="8" r="2.6"/>'
            '<path d="M1.5 18c0-3.3 2.5-5.5 5.5-5.5s5.5 2.2 5.5 5.5"/>'
            '<path d="M13 18c0-2.6 1.6-4.3 3.6-4.3S20 15.4 20 18"/>',
 'alvo':    '<circle cx="10.5" cy="10.5" r="8.4"/><circle cx="10.5" cy="10.5" r="4.4"/>'
            '<circle cx="10.5" cy="10.5" r="1.1" fill="currentColor"/>',
 'doc':     '<path d="M4.5 2.5h8l4 4v12a1 1 0 01-1 1h-11a1 1 0 01-1-1z"/>'
            '<path d="M12.5 2.5v4h4"/><path d="M7 11h7M7 14.5h7"/>',
 'grafico': '<path d="M3 18.5V9M8.5 18.5V4M14 18.5v-6.5M19.5 18.5V7"/>',
 'caixa':   '<path d="M10.5 2.5l8 4.3v8.4l-8 4.3-8-4.3V6.8z"/><path d="M2.5 6.8l8 4.3 8-4.3M10.5 11.1v8.4"/>',
 'alerta':  '<path d="M10.5 2.8L19.6 18H1.4z"/><path d="M10.5 8.2v4.6M10.5 15.2v.1"/>',
 'escudo':  '<path d="M10.5 2.2l7.3 2.9v5.6c0 4.3-3 7.2-7.3 8.6-4.3-1.4-7.3-4.3-7.3-8.6V5.1z"/>',
 'politica':'<path d="M4.5 2.5h12v16h-12z"/><path d="M7.5 6.5h6M7.5 10h6M7.5 13.5h4"/>',
 'check':   '<path d="M5 3.5h11v15H5z"/><path d="M8 10.3l2.2 2.2L14 8.8"/>',
 'conserto':'<path d="M4 18.5l6-6"/><path d="M13.5 2.8a4.6 4.6 0 00-3.3 7.8l-7.4 7.4 1.6 1.6 7.4-7.4A4.6 4.6 0 1013.5 2.8z"/>',
 'lupa':    '<circle cx="9" cy="9" r="6.2"/><path d="M13.6 13.6l4.6 4.6"/>',
 'elo':     '<path d="M8.4 12.6a4 4 0 010-5.6l2.1-2.1a4 4 0 115.6 5.6l-1 1"/>'
            '<path d="M12.6 8.4a4 4 0 010 5.6l-2.1 2.1a4 4 0 11-5.6-5.6l1-1"/>',
 'banco':   '<ellipse cx="10.5" cy="5" rx="7.3" ry="2.7"/><path d="M3.2 5v10.6c0 1.5 3.3 2.7 7.3 2.7s7.3-1.2 7.3-2.7V5"/>'
            '<path d="M3.2 10.3c0 1.5 3.3 2.7 7.3 2.7s7.3-1.2 7.3-2.7"/>',
 'engre':   '<circle cx="10.5" cy="10.5" r="3.2"/><path d="M10.5 1.6v2.8M10.5 16.6v2.8M19.4 10.5h-2.8M4.4 10.5H1.6'
            'M16.8 4.2l-2 2M6.2 14.8l-2 2M16.8 16.8l-2-2M6.2 6.2l-2-2"/>',
 'faisca':  '<path d="M10.5 1.8l2 5.5 5.5 2-5.5 2-2 5.5-2-5.5-5.5-2 5.5-2z"/>',
 'rede':    '<circle cx="4.5" cy="5" r="2.4"/><circle cx="4.5" cy="16" r="2.4"/><circle cx="16.5" cy="10.5" r="2.4"/>'
            '<path d="M6.7 6.1l7.7 3.3M6.7 14.9l7.7-3.3"/>',
 'veloc':   '<path d="M2.6 15.5a8.6 8.6 0 1115.8 0"/><path d="M10.5 15.5l4-4.6"/>',
 'mapa':    '<path d="M1.8 4.6l5.8-2.2 5.8 2.2 5.8-2.2v14l-5.8 2.2-5.8-2.2-5.8 2.2z"/>'
            '<path d="M7.6 2.4v14M13.4 4.6v14"/>',
 'subir':   '<path d="M10.5 15.5V3.4"/><path d="M5.6 8.3l4.9-4.9 4.9 4.9"/><path d="M2.6 18.5h15.8"/>',
}

def ico(x, y, nome, cor, tam=1.0, lg=1.7):
    a(f'<g transform="translate({x},{y}) scale({tam})" fill="none" stroke="{cor}" '
      f'stroke-width="{lg}" stroke-linecap="round" stroke-linejoin="round" color="{cor}">'
      + ICO.get(nome, '') + '</g>')

def seta(d, cor='#94A3B8', lg=1.6):
    a(f'<path d="{d}" stroke="{cor}" stroke-width="{lg}" fill="none" marker-end="url(#m)"/>')

a(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" '
  f'font-family="{F}" role="img" aria-label="Hormos: da estratégia à evidência — a cadeia do SGSI">')
a('<title>Hormos — da estratégia à evidência</title>')
a('<defs><marker id="m" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" '
  'orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#94A3B8"/></marker>'
  '<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">'
  '<stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#F1F5F9"/></linearGradient></defs>')
a(f'<rect width="{W}" height="{H}" fill="url(#bg)"/>')

# ── Cabeçalho ───────────────────────────────────────────────────────────
a('<g transform="translate(30,22) scale(0.78)">'
  '<rect width="64" height="64" rx="14" fill="#0B0F14"/>'
  '<path d="M8.75 49.5 L18.94 38.51" fill="none" stroke="#2563EB" stroke-width="5.5" stroke-linecap="round"/>'
  '<path d="M29.28 36.99 L31.52 38.31" fill="none" stroke="#2563EB" stroke-width="5.5" stroke-linecap="round"/>'
  '<path d="M40.99 36.11 L55.25 14.5" fill="none" stroke="#2563EB" stroke-width="5.5" stroke-linecap="round"/>'
  '<circle cx="23.5" cy="33.6" r="5.05" fill="none" stroke="#60A5FA" stroke-width="3.3"/>'
  '<circle cx="37.3" cy="41.7" r="5.05" fill="none" stroke="#60A5FA" stroke-width="3.3"/></g>')
txt(108, 52, 'Hormos', 30, TINTA, 700)
txt(110, 72, 'GRC para um mundo mais seguro', 11, FRACO)
a(f'<line x1="350" y1="24" x2="350" y2="82" stroke="{BORDA}" stroke-width="1.5"/>')
txt(382, 50, 'Da estratégia à evidência.', 26, TINTA, 700)
txt(382, 75, 'Tudo conectado. Em um só lugar.', 15, '#2563EB', 500)
for i, l in enumerate(['O Hormos transforma requisitos de normas',
                       'em uma cadeia de causa e efeito, integrada e',
                       'rastreável, da estratégia à evidência.']):
    txt(W-30, 36+i*17, l, 11.5, FRACO, 400, 'end')

# ── Contexto e direcionamento ───────────────────────────────────────────
ctx = [('Partes Interessadas', ['Exigências e expectativas', '(clientes, reguladores, sociedade)'], 'pessoas'),
       ('Objetivos de Segurança', ['Metas e direção do SGSI', 'ISO 27001 — 6.2'], 'alvo'),
       ('Requisitos e Normas', ['ISO 27001, LGPD, CIS, NIST,', 'COBIT, iGovTIC-JUD'], 'doc'),
       ('Análise Crítica da Direção', ['Decisões e melhoria contínua', 'ISO 27001 — 9.3'], 'grafico')]
cw, cg, cy, ch = 348, 14, 108, 78
for i, (t, subs, ic) in enumerate(ctx):
    x = 30 + i*(cw+cg)
    cxa(x, cy, cw, ch, 10, '#FFFFFF')
    a(f'<rect x="{x+16}" y="{cy+18}" width="32" height="32" rx="8" fill="#2563EB12"/>')
    ico(x+21, cy+23, ic, '#2563EB', 1.05)
    txt(x+58, cy+28, t, 13, TINTA, 700)
    for j, s in enumerate(subs):
        txt(x+58, cy+46+j*15, s, 10.5, FRACO)

txt(W/2, cy+ch+42, 'CONTEXTO E DIRECIONAMENTO', 11, TINTA, 800, 'middle', '.1em')
txt(W/2, cy+ch+58, 'O ambiente em que o SGSI existe e o que ele precisa alcançar.', 11, FRACO, 400, 'middle')

ye = 268
for i in range(4):
    x = 30 + i*(cw+cg) + cw/2
    seta(f'M{x} {cy+ch} L{x} {cy+ch+14} L{x if i<2 else x} {cy+ch+14}')
seta(f'M{W/2} {cy+ch+66} L{W/2} {ye-10}')

# ── As 9 etapas ─────────────────────────────────────────────────────────
import igovtic
_cat = igovtic.carregar(max(igovtic.ciclos_disponiveis()))
_n = sum(1 for g in ('perguntas_tic','perguntas_negocio') for q in _cat[g]
         for it in q['itens'] for _ in it['subitens'])

E = [('Contexto\ndo SGSI', 'Entenda o cenário,\npartes interessadas\ne defina objetivos.', 'ISO 27001\n4.1 · 4.2 · 6.2', '#3B82F6'),
     ('Ativos\nde Informação', 'Identifique o que tem\nvalor e suas\ndependências.', 'A.5.9 · ISO 27005', '#22C55E'),
     ('Análise\nde Riscos', 'Avalie ameaças,\nimpactos e defina\no tratamento.', '6.1.2 · 6.1.3\n8.2 · 8.3', '#F59E0B'),
     ('Declaração de\nAplicabilidade (SOA)', 'Selecione e justifique\nos controles do\nAnexo A.', '6.1.3(d)\nAnexo A', '#EF4444'),
     ('Políticas\ne Normativos', 'Documente o que\na organização faz.', '7.5 · A.5.1', '#A855F7'),
     ('Evidências', 'Comprove a\nimplementação\nna prática.', 'A.5.37 · 9.1', '#06B6D4'),
     ('Eventos e\nNão Conformidades', 'Registre ocorrências,\nincidentes e desvios.', 'A.5.24–27 · 10.2\nLGPD Art. 48', '#F97316'),
     ('Causa raiz\ne Planos de Ação', 'Corrija, trate a causa\ne verifique a eficácia.', '10.2', '#84CC16'),
     ('Auditoria\nInterna', 'Avalie a conformidade\ne gere achados.', '9.2', '#D946EF')]
ICO_E = ['doc', 'caixa', 'alerta', 'escudo', 'politica', 'check', 'alerta', 'conserto', 'lupa']

ew, eg = 154, 10
ex0, ey, eh = 30, ye, 272
for i, (tit, desc, cla, cor) in enumerate(E):
    x = ex0 + i*(ew+eg)
    cxa(x, ey, ew, eh, 12, f'{cor}0E', f'{cor}44', 1.4)
    a(f'<circle cx="{x+22}" cy="{ey+22}" r="13" fill="{cor}"/>')
    txt(x+22, ey+27, str(i+1), 13, '#FFFFFF', 800, 'middle')
    ico(x+ew/2-10.5, ey+46, ICO_E[i], cor, 1.25, 1.8)
    ls = tit.split('\n')
    for j, l in enumerate(ls):
        txt(x+ew/2, ey+100+j*17, l, 12.5, TINTA, 700, 'middle')
    base = ey + 100 + len(ls)*17 + 14
    for j, l in enumerate(desc.split('\n')):
        txt(x+ew/2, base+j*15, l, 10.5, FRACO, 400, 'middle')
    cl = cla.split('\n')
    ch2 = 22 + (len(cl)-1)*15
    cy2 = ey + eh - ch2 - 14
    a(f'<rect x="{x+12}" y="{cy2}" width="{ew-24}" height="{ch2}" rx="7" fill="{cor}22"/>')
    for j, l in enumerate(cl):
        txt(x+ew/2, cy2+15+j*15, l, 10.5, TINTA, 700, 'middle')
    if i < 8:
        seta(f'M{x+ew} {ey+eh/2} L{x+ew+eg-2} {ey+eh/2}')

# ── Melhoria contínua ───────────────────────────────────────────────────
yl = ey + eh + 34
xa, xb = ex0 + ew/2, ex0 + 8*(ew+eg) + ew/2
a(f'<path d="M{xb} {ey+eh} L{xb} {yl} L{xa} {yl} L{xa} {ey+eh}" stroke="#94A3B8" '
  f'stroke-width="1.6" fill="none" marker-end="url(#m)"/>')
a(f'<rect x="{W/2-230}" y="{yl-13}" width="460" height="26" fill="url(#bg)"/>')
txt(W/2, yl-1, 'MELHORIA CONTÍNUA · ISO 27001 — 10.1', 11, TINTA, 800, 'middle', '.08em')
txt(W/2, yl+15, 'As lições aprendidas alimentam o próximo ciclo do SGSI.', 11, FRACO, 400, 'middle')

# ── Base única de dados ─────────────────────────────────────────────────
yb = yl + 36
cxa(30, yb, W-60, 104, 12, '#FFFFFF')
a(f'<rect x="52" y="{yb+28}" width="40" height="40" rx="9" fill="#1E293B"/>')
for k in range(3):
    a(f'<ellipse cx="72" cy="{yb+40+k*9}" rx="12" ry="4" fill="none" stroke="#FFFFFF" stroke-width="1.6"/>')
txt(108, yb+40, 'BASE ÚNICA', 14, TINTA, 800)
txt(108, yb+58, 'DE DADOS', 14, TINTA, 800)
txt(108, yb+76, 'Uma informação, múltiplos usos.', 10.5, FRACO)
ICO_B = ['elo', 'banco', 'engre', 'faisca', 'rede']
itens = [('Rastreabilidade', ['De onde veio e no que deu']),
         ('Sem retrabalho', ['Cadastre uma vez,', 'use em todo o sistema']),
         ('Correlação automática', ['Entre normas, controles,', 'riscos e evidências']),
         ('Apoio da IA', ['Recomendações com', 'base no seu contexto, local']),
         ('Conformidade multi-framework', ['ISO · LGPD · CIS · NIST · COBIT', f'iGovTIC-JUD ({_n} subitens)'])]
bx, bg2 = 332, 240
for i, (t, subs) in enumerate(itens):
    x = bx + i*bg2
    ico(x, yb+32, ICO_B[i], '#2563EB', 0.95, 1.7)
    txt(x+32, yb+40, t, 11.5, TINTA, 700)
    for j, s in enumerate(subs):
        txt(x+32, yb+57+j*14, s, 10, FRACO)

# ── Resultados ──────────────────────────────────────────────────────────
yr = yb + 122
seta(f'M{W/2} {yb+104} L{W/2} {yr-8}')
cxa(30, yr, W-60, 100, 12, '#FFFFFF')
a(f'<rect x="52" y="{yr+30}" width="40" height="40" rx="9" fill="#2563EB14"/>')
for k, hh in enumerate((10, 18, 26)):
    a(f'<rect x="{60+k*10}" y="{yr+60-hh}" width="6" height="{hh}" rx="2" fill="#2563EB"/>')
txt(108, yr+46, 'RESULTADOS', 14, TINTA, 800)
txt(108, yr+64, 'Informação para decisão.', 10.5, FRACO)
ICO_R = ['veloc', 'mapa', 'grafico', 'doc', 'subir']
res = [('Dashboard Executivo', ['Visão consolidada: riscos,', 'maturidade e planos']),
       ('Análise de GAP', ['Fila priorizada —', 'o que fazer primeiro']),
       ('Postura GRC', ['Maturidade por framework,', 'cada um na sua natureza']),
       ('Relatórios', ['Prontos para auditoria', 'e para a direção']),
       ('Envio ao INTEGRA', ['Anexos no formato exigido', 'pelo CNJ (iGovTIC-JUD)'])]
rw = 238
for i, (t, subs) in enumerate(res):
    x = 292 + i*rw
    cxa(x, yr+16, rw-14, 68, 9, FUNDO, BORDA, 1)
    ico(x+13, yr+30, ICO_R[i], '#2563EB', 0.92, 1.7)
    txt(x+44, yr+38, t, 11, TINTA, 700)
    for j, s in enumerate(subs):
        txt(x+44, yr+53+j*13, s, 9.5, FRACO)

# ── Rodapé ──────────────────────────────────────────────────────────────
yf = yr + 108
a(f'<rect x="0" y="{yf}" width="{W}" height="{H-yf}" fill="{ESCURO}"/>')
a(f'<g transform="translate(30,{yf+14}) scale(0.42)">'
  '<path d="M8.75 49.5 L18.94 38.51" fill="none" stroke="#60A5FA" stroke-width="6" stroke-linecap="round"/>'
  '<path d="M29.28 36.99 L31.52 38.31" fill="none" stroke="#60A5FA" stroke-width="6" stroke-linecap="round"/>'
  '<path d="M40.99 36.11 L55.25 14.5" fill="none" stroke="#60A5FA" stroke-width="6" stroke-linecap="round"/>'
  '<circle cx="23.5" cy="33.6" r="5.05" fill="none" stroke="#93C5FD" stroke-width="3.6"/>'
  '<circle cx="37.3" cy="41.7" r="5.05" fill="none" stroke="#93C5FD" stroke-width="3.6"/></g>')
txt(68, yf+30, 'Hormos', 17, '#FFFFFF', 700)
txt(150, yf+30, 'GRC que conecta pessoas, processos e evidências.', 11.5, '#CBD5E1')
txt(W-30, yf+30, 'Mais conformidade. Mais confiança. Mais valor.', 11.5, '#CBD5E1', 400, 'end')
a('</svg>')

import pathlib
pathlib.Path('/tmp/ico/hormos-cadeia.svg').write_text('\n'.join(o), encoding='utf-8')
print('  SVG gerado')
