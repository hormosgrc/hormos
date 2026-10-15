# Guia de cada tela

O que você faz em cada lugar, o que o sistema faz sozinho e o que ele vai
cobrar de você.

## Visão geral

### Dashboard
**Você faz:** nada, é leitura.
**O sistema faz:** resume o estado do SGSI e monta um briefing determinístico
com até três prioridades, correlacionando problema-raiz.
**O sistema cobra:** indicador sem base de dados aparece como "sem dados", em
cinza — nunca em verde. Verde significa medido e dentro da meta.

### Postura GRC
**O sistema faz:** mostra cada framework na natureza dele — ISO por
certificação, CIS por Grupo de Implementação, NIST por função.
**O sistema cobra:** não existe número único somando normas diferentes; seria
média de coisas incomparáveis.

### Frameworks GRC — 6.1.3, 9.1
**Você faz:** avalia a maturidade de cada controle (0 a 5, CMMI) e define a meta.
**O sistema faz:** salva a cada clique, sem botão de gravar; guarda onde você
parou; propõe o mapeamento entre normas.
**O sistema cobra:** framework fora do escopo contratado mostra a cobertura que
ele já herdaria — não é cadeado cego.

### Análise de GAP
**O sistema faz:** ordena a fila por obrigatoriedade, depois risco, depois
distância até a meta.
**O sistema cobra:** requisito mandatório das cláusulas 4 a 10 não atendido
aparece como bloqueador da certificação.

### Relatórios
**O sistema faz:** produz os oito relatórios que um auditor externo pede, com a
marca da instância no cabeçalho — executivo, GAP, auditoria, evolução,
mapeamento multi-framework, LGPD, iGovTIC-JUD e o Relatório Anual do art. 8º
da Res. CMN 4.893.
**O sistema cobra:** o relatório de evolução não traça tendência com um ponto só.

### BACEN Res. CMN 4.893 — instituições autorizadas pelo Banco Central

Chega por **Frameworks GRC**, mas tem três painéis próprios que os demais não
têm, porque a régua é de regulador e não de norma de gestão.

**Perfil da instituição.** Oito declarações que a própria resolução condiciona:
tipo de instituição, se opera na RSFN (Pix/STR), se é participante de SMF, se
contrata nuvem no exterior, se adota a política do conglomerado, se tem comitê
de risco, se tem auditoria interna, se usa SaaS pela internet. Cada "não" marca
os requisitos correspondentes como **não aplicáveis**, com a justificativa
citando o artigo. Avaliação que você fez à mão **nunca é apagada** por isso.

> O primeiro campo decide tudo: pelo art. 1º, parágrafo único, a 4.893 **não se
> aplica** a instituição de pagamento, corretora, distribuidora nem
> administradora de consórcio. Se for o seu caso, a tela avisa — e a régua
> correta é a Res. BCB 85/2021.

**Conformidade.** O veredito que o Banco Central lê: **atende / atende
parcialmente / não atende / não aplicável**, com o motivo de cada um. O
percentual é sobre o **exigível**, nunca sobre os 152 — pôr o inaplicável no
denominador faz o número mentir para baixo. Atender exige maturidade 3 ou mais,
evidência vigente e nenhum prazo em falta.

**Prazos e periodicidade.** Quatro seções: obrigações disparadas por evento
(cada contratação de nuvem cria uma, com prazo de dez dias), o ciclo anual do
relatório, os periódicos e a guarda de cinco anos do art. 23. O veredito é
sempre **calculado das duas datas** — não existe campo para declarar "no prazo"
o que está fora.

**Declaração de não ocorrência.** Para os oito requisitos em que a ausência do
fato é legítima, você declara formalmente que nada ocorreu no exercício. Fica
com o seu nome e a data: é isso que a torna formal.

O **Relatório Anual** (art. 8º) sai em *Relatórios*.

### iGovTIC-JUD — órgãos do Poder Judiciário

O diagnóstico anual de governança de TIC que o CNJ cobra (Res. CNJ 370/2021,
art. 11). Tela própria, em **/igovtic**.

São **28 perguntas de TIC** e **10 da área de negócio**, com a nota oficial de
cada subitem para o segmento do órgão — a mesma resposta vale pontos diferentes
conforme o segmento, e o catálogo traz as cinco colunas. Cada clique recalcula
o índice, o nível e quanto falta para a faixa seguinte.

**O sistema mostra DOIS índices:** o que você declarou e o que o CNJ daria. A
conformidade é julgada **por item**, não por subitem: um subitem declarado sem
evidência válida no período zera o item inteiro — inclusive o que estava
provado. Ver os dois lado a lado é a diferença entre saber a nota e descobri-la
depois do envio.

Ao lado de cada subitem, o Hormos mostra **o que o SGSI já comprova**: o
crosswalk curado liga 132 dos 208 subitens de TIC a controles da ISO 27001 —
e, onde a 27001 não tem o que dizer, à ISO 42001 (modelos de IA) e à LGPD. O
resto é faixa percentual ou pesquisa de percepção, que não têm equivalente em
norma e ficam sem âncora de propósito.

### Envio ao INTEGRA

O CNJ não recebe um relatório: recebe **um anexo por item de conformidade**,
submetido no INTEGRA. A tela lista os **31 anexos**, confere as regras de forma
de cada um e baixa o arquivo pronto — PDF único com a capa obrigatória, ou ZIP
quando o item também exige a planilha-modelo do CNJ.

Confere antes do envio o que reprova por forma: capa ausente, PDF sem OCR,
evidência fora do período e planilha-modelo alterada. E destaca no PDF o trecho
que prova cada resposta, citando a página na capa.

## O SGSI

### Ativos de Informação — A.5.9, A.5.29, ISO 27005
**Você faz:** cadastra ativos primários e de suporte, com dono, criticidade, CID
e dependências.
**O sistema faz:** calcula a saúde de cada ativo somando riscos, NCs e planos
atrasados dele; mostra o RoPA e os cenários de continuidade ali dentro.
**O sistema cobra:** a distinção primário × suporte.

### Contexto do SGSI — 4.1, 4.2, 6.2
**Você faz:** declara partes interessadas com suas exigências e os objetivos de
segurança com meta e prazo.
**O sistema faz:** transforma objetivo e expectativa em risco, herdando o texto.
**O sistema cobra:** objetivo precisa de meta e prazo.

### Análise de Riscos — 6.1.2, 6.1.3
**Você faz:** avalia probabilidade e impacto inerentes, escolhe o tratamento e o
controle, e reavalia o residual.
**O sistema faz:** calcula o nível, monta a matriz clicável e gera plano ou NC.
**O sistema cobra:** aceitar risco exige aprovador nomeado e data (6.1.3f).

### Eventos & Não Conformidades — A.5.24–27, 10.1, LGPD Art. 48
**Você faz:** registra o que aconteceu ou foi encontrado e classifica a natureza.
**O sistema faz:** sugere o risco relacionado; se envolve dado pessoal, inicia
os prazos legais contando dias úteis, com feriados nacionais.
**O sistema cobra:** encerrar NC exige causa raiz registrada e eficácia
avaliada. E avisa se a mesma causa já apareceu antes.

### Planos de Ação — 6.1.3, 10.2
**Você faz:** define o que será feito, por quem e até quando.
**O sistema faz:** marca o atraso sozinho e mostra o plano na NC, no risco, no
ativo e no painel.
**O sistema cobra:** plano sem dono e sem prazo não é plano, é intenção.

### Políticas & Normativos — 7.5, A.5.1
**Você faz:** publica os documentos e amarra cada um aos controles que cobre.
**O sistema faz:** eleva o controle a "Documentado" e propaga a cobertura para
os frameworks equivalentes.
**O sistema cobra:** documento não vira implementação.

### Evidências — A.5.37, 9.1
**Você faz:** anexa a prova operacional, com data de coleta e periodicidade.
**O sistema faz:** lê o conteúdo (PDF, Word, PowerPoint, TXT; imagem por OCR) e
sugere os controles cobertos.
**O sistema cobra:** a sugestão é para você confirmar, nunca automática. E
evidência vencida deixa de contar como cobertura.

### Auditoria Interna — 9.2
**Você faz:** planeja o escopo, designa o auditor e registra achados com método
e amostra.
**O sistema faz:** gera o roteiro do que a organização declarou no SOA e
converte achado em NC com o contexto.
**O sistema cobra:** sinaliza conflito de imparcialidade (9.2.2c) e exige
parecer do auditor antes de concluir.

### Análise Crítica — 9.3
**Você faz:** registra a reunião da direção, anexa a ata e escreve as decisões.
**O sistema faz:** congela um retrato dos indicadores e confere a ata contra as
oito entradas da 9.3, citando o trecho de cada uma.
**O sistema cobra:** sem ata anexada, a 9.3 fica sem a informação documentada
que ela exige reter.

### Privacidade (LGPD) — Art. 37, 41, 48
**Você faz:** mantém o RoPA dentro dos ativos primários e designa o Encarregado.
**O sistema faz:** conta os prazos legais e mostra o que está por vencer.
**O sistema cobra:** dado sensível exige base do Art. 11, não do Art. 7.
Legítimo interesse exige o teste de balanceamento.

## Três coisas que valem saber

**A inteligência artificial roda na sua máquina.** Nenhum conteúdo do seu SGSI
sai da sua rede. Desligando o serviço de IA, o produto continua funcionando
inteiro — ela é acessória, não estrutural.

**O que a IA sugere, você confirma.** Correlação de evidência, rascunho de
parecer e proposta de mapeamento são sugestões. Medimos o acerto contra um
conjunto de documentos rotulados à mão: ela acerta a maioria e recusa o que não
é evidência, mas erra o suficiente para que a confirmação humana não seja
opcional.

**Seus dados são seus.** Cada registro tem exportação em CSV, e a exportação
continua disponível mesmo com a licença vencida — nesse caso o sistema entra em
somente leitura, sem nunca reter o que é seu.

## API v1 — não é tela, e por isso some do guia

Quem procura aqui e não acha conclui que o produto não tem. Tem: importar
planilha, integrar com outro sistema e puxar dados, nos planos **Essencial e
Avançado**. A autenticação usa o Keycloak embarcado (`client_credentials`),
sem componente novo.

Duas coisas sobre ela que mudam a operação:

**Vem desligada.** Serve ao começo — importação, migração — e depois costuma
ficar esperando parada. Desligada responde `404`: nem o endereço existe.
Liga-se em **Configurações da Empresa → API v1**, por conta Administrador, e a
troca fica no rastro de auditoria. Quem já usava a API antes de atualizar
continua com ela ligada.

**Atende na porta 9443**, separada da porta das pessoas. Isso existe para quem
cuida da rede: a API pode ser fechada no firewall, restringida a uma VPN ou
limitada por taxa no equipamento que a empresa já tem, sem que nada disso toque
o acesso das pessoas. Chamar `/api/v1` na porta do portal devolve `404`
apontando a porta certa.

Os exemplos de `curl` e a criação do cliente de serviço no Keycloak estão em
**[API v1](api.md)**.

## Modo auditor (Edição Avançada)

Só aparece quando o modo auditor está ligado em **Configurações da Empresa** —
e só uma conta **Administrador** liga.

### Empresas clientes

A carteira. Cada cliente tem **banco de dados próprio**: não é um
compartimento dentro da mesma base, é outra base, e o PostgreSQL recusa a
referência cruzada entre eles.

A tabela traz o farol de cada um — **bom, atenção, crítico** — com nota,
cobertura, maturidade, riscos altos, NC abertas e planos vencidos. Cliente sem
avaliação aparece como **"sem dados"**, não como "crítico": são coisas
diferentes. E cliente cuja base não responde no momento da consulta aparece
como **"indisponível"** — é falha de leitura, não diagnóstico sobre ele.

- **Nova empresa** cria a base, replica o esquema e registra. A empresa nasce
  vazia; dados de demonstração não entram em base de cliente real.
- **Entrar** passa a operar dentro daquele cliente. Enquanto você está lá, uma
  faixa fixa no topo do menu diz em qual empresa você está — editar o cliente
  errado achando que é outro é o pior erro possível aqui.
- **Desativar** tira da operação e **não apaga nada**: o art. 23 da Res. CMN
  4.893 manda guardar cinco anos, e contrato de auditoria costuma mandar mais.

Entrar numa empresa cliente fica registrado no rastro de auditoria: é o momento
em que alguém da firma passa a ver dado de um cliente específico.
