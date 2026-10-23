# Hormos — Appliance

Plataforma de GRC auto-hospedada: ISO 27001, LGPD, CIS Controls v8, NIST CSF,
COBIT 2019, ISO 42001, **BACEN Res. CMN 4.893** e **iGovTIC-JUD (CNJ)**, com
correlação entre normas e IA local. Opera **uma** empresa ou, no **modo
auditor**, uma carteira de clientes com banco de dados separado para cada um.

> **ὅρμος** (*hórmos*), do grego: o ancoradouro abrigado onde o navio para no
> meio da viagem — e também o colar, contas presas num mesmo fio. Os dois
> sentidos descrevem o produto. Ninguém certifica — **nem se mantém
> certificado** — da noite para o dia: a conformidade não é um destino que se
> alcança e encerra, é uma travessia que continua depois do certificado. O
> Hormos é a parada segura ao longo dela, com ativo, risco, controle,
> evidência e plano num fio só. O símbolo é esse fio, com duas contas.


<p align="center">
  <img src="docs/img/hormos-cadeia.svg" alt="Da estratégia à evidência: as nove etapas do SGSI com a cláusula ISO de cada uma, a base única de dados e os resultados." width="100%">
</p>

O diagrama acima é gerado por `scripts/gerar-infografico.py` — os números saem
do catálogo, não são digitados: diagrama que afirma "238 subitens" não pode
envelhecer em silêncio quando o ciclo mudar.

**Este é o repositório público**: compose, gateway, autenticação, esquema de
banco, instaladores e documentação. O código do portal e o licenciador vivem em
repositórios próprios e privados.

| repositório | conteúdo | visibilidade |
|---|---|---|
| `hormos` (este) | appliance, instaladores, documentação | público |
| `hormos-portal` | código do portal — vira a imagem distribuída | privado |
| `hormos-licenciador` | emissão de licenças, chave privada Ed25519 | privado |

## Requisitos

O Hormos tem **duas** configurações, e a diferença entre elas é o Analista IA.
Sem ele o produto é leve; com ele, o requisito é o do modelo de linguagem.

### Sem o Analista IA

| | mínimo |
|---|---|
| **Sistema** | Linux, macOS ou Windows 10/11 |
| **Docker** | Engine 24+ e Compose v2 |
| **RAM livre para o Docker** | **2 GB** |
| **Disco** | **4 GB** |
| **CPU** | 2 núcleos |

O **motor semântico embarcado** continua funcionando sem LLM: correlação de
evidência por embeddings, análise de GAP, índices e relatórios. O que não há é
a redação dos pareceres em linguagem natural.

### Com o Analista IA

| | avaliação / teste | produção |
|---|---|---|
| **RAM livre para o Docker** | **8 GB** | **8 GB** |
| **RAM do dispositivo** | **12 GB** | **16 GB** |
| **CPU** | Core i5 11ª geração / Ryzen 5, 4 núcleos | 6+ núcleos |
| **GPU** | **não é necessária** | não é necessária |
| **Disco** | 16 GB | 20 GB |

**Não existe versão reduzida da IA.** O Hormos usa **um** modelo para tudo — o
**Qwen3-8B**, de 2025, escolhido em medição contra o Qwen2.5-7B que o produto
usava antes (ver [Analista IA embarcado](#analista-ia-embarcado-offline)) —
parecer de risco, causa raiz, não conformidade, plano — e não há tarefa leve
despachada para um modelo menor. Já houve uma escada (7B / 3B / 1.5B por RAM
disponível) e ela foi removida: o modelo pequeno não entregava "menos IA",
entregava o **mesmo parecer, pior**, com a nossa marca. Abaixo de 8 GB, o
instalador recusa a IA e segue sem ela, em vez de degradar em silêncio.

**Por que 12 GB no dispositivo se o Hormos pede 8.** Os 8 GB são o que o Docker
precisa ter disponível. Sobram os 4 GB para o sistema operacional e o resto da
máquina — e é por isso que um notebook de 8 GB **não** serve: nele o Docker
nunca terá 8 livres.

**Por que a GPU não entra.** O appliance roda o modelo em CPU, por desenho: ele
é instalado na infraestrutura do cliente, que raramente tem GPU no servidor de
aplicação. Com GPU é mais rápido, mas nada no produto depende disso.

| | Portas | Internet |
|---|---|---|
| | 443 (e 80 só com domínio próprio); 9443 se a API for ligada | só para baixar as imagens na 1ª vez |

Depois da instalação o appliance **não fala com a internet**. Nem a IA, nem o licenciamento (validado offline por assinatura Ed25519), nem a consulta ao registro público do CNJ — ele viaja dentro do produto. A contrapartida está dita em [iGovTIC-JUD](#igovtic-jud--o-índice-que-o-cnj-cobra-do-judiciário).

Medido nesta instalação, não estimado: o stack sem IA ocupa **~1 GB de RAM**
(Keycloak é o maior, 660 MB; o portal, 138 MB) e **~1,8 GB de imagens**.

**Windows não precisa de Docker Desktop.** O `install.bat` instala WSL2 e o
Docker Engine dentro dele — assim o licenciamento do Desktop (pago acima de
250 funcionários ou US$ 10 mi de receita) não se aplica.

O **Analista IA é opcional** e usa **um único modelo** — o **Qwen3-8B** — que
exige 8 GB de RAM livres ao Docker. Abaixo disso o instalador recusa a IA e
segue sem ela — não há versão reduzida (ver [Requisitos](#requisitos)).

Sem o LLM o produto funciona inteiro: o **motor semântico** (embeddings locais,
~300 MB) é quem faz a correlação, e roda com folga. O LLM só refina a redação
dos pareceres — **os fatos vêm sempre do motor**, e um refino que perca algum
registro é descartado em favor do texto técnico completo.

**Nada sai da sua rede.**

## Instalação (cliente)

```bash
./install.sh          # Linux/macOS
install.bat           # Windows (instala WSL2 + Docker Engine)
```

O compose puxa a **imagem publicada e assinada** — não constrói a partir do
código-fonte.

### A senha do primeiro acesso é de uso único

No fim da instalação o script mostra o usuário e a senha do administrador. A
senha é **gerada naquela instalação** (96 bits), então cada cliente recebe a
sua — e ela precisa ser mostrada, porque ninguém mais a conhece.

O que a protege não é escondê-la: é o Keycloak **exigir a troca no primeiro
acesso**. Isso importa porque a linha impressa sobrevive no scrollback do
terminal, em qualquer `./install.sh | tee install.log` e em transcrição de
instalação colada num chamado de suporte — todos caminhos reais. Sendo de uso
único, nada disso serve depois da primeira entrada.

Feche o terminal quando terminar, e não cole a saída da instalação em e-mail ou
chamado sem apagar essa linha.

### Conferindo a assinatura antes de rodar

Dizer que a imagem é assinada e não mostrar como conferir é pedir confiança.
Você não precisa instalar o cosign: o Docker que já é pré-requisito basta.

```bash
docker run --rm ghcr.io/sigstore/cosign/cosign:latest verify \
  ghcr.io/hormosgrc/hormos-portal:2.2.5 \
  --certificate-identity 'sgduarte7@gmail.com' \
  --certificate-oidc-issuer 'https://accounts.google.com'
```

A assinatura é **cosign keyless** (Sigstore) e o registro público de
transparência guarda a prova. A identidade do assinante é **fixada** no
comando de propósito: com `--certificate-identity-regexp '.*'` você provaria
apenas que a imagem foi assinada por *alguém* — quem publicasse a própria
imagem, assinada com a própria conta, passaria no teste.

## Desenvolvimento

Clone o repositório do portal ao lado deste e use o override:

```bash
git clone <privado>/hormos-portal ../hormos-portal
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
```

## Licenciamento

Source-available sob **Elastic License 2.0** (`LICENSE`), com EULA para uso
comercial (`EULA.md`) e avisos de terceiros em `NOTICE`. Não é software livre:
fornecer como serviço gerenciado e contornar a chave de licença são vedados.

---

# Hormos v2.2.5

**Plataforma de Governança, Riscos e Conformidade** — Multi-framework, self-hosted, sem licenciamento por usuário.

## Frameworks pré-carregados

| Framework | Versão | Controles |
|-----------|--------|-----------|
| ISO/IEC 27001 | 2022 | 93 controles do Anexo A + 23 requisitos (cláusulas 4–10) |
| CIS Controls | v8 | 153 salvaguardas (IG1/IG2/IG3) |
| NIST CSF | 2.0 | 106 subcategorias (6 funções, incl. GOVERNAR) |
| COBIT 2019 | 2019 | 40 objetivos (EDM, APO, BAI, DSS, MEA) |
| ISO/IEC 42001 | 2023 | 38 controles do Anexo A + 26 requisitos |
| LGPD | 2018 | 23 artigos-chave |
| **BACEN Res. CMN 4.893** | **vigente em 19/12/2025** | **152 requisitos por artigo, parágrafo e inciso** |
| iGovTIC-JUD | ciclo 2026 | 238 subitens · 28 perguntas de TIC + 10 de negócio |

**Total: 631 controles e requisitos pré-carregados**, mais os 238 subitens do
iGovTIC-JUD, que têm catálogo próprio porque a régua dele é outra.

### BACEN Res. CMN 4.893 — o que o Banco Central cobra das instituições

Primeiro framework **regulatório brasileiro** do Hormos, na versão **vigente
consolidada em 19/12/2025** (texto original alterado pelas Res. CMN 5.117/2024
e 5.274/2025). O catálogo é a **resolução**, aberta por artigo, parágrafo e
inciso — não o questionário de um auditor, que é sempre o recorte de um
auditor para uma instituição num ano.

**Âmbito, e este é o erro mais caro possível:** pelo art. 1º, parágrafo único,
a 4.893 **não se aplica** a instituições de pagamento, corretoras,
distribuidoras nem administradoras de consórcio — essas seguem a Res. BCB
85/2021. Banco, financeira e SCD caem aqui. Aplicar a régua errada deixa as
duas telas com a mesma aparência de certo, e por isso o produto avisa.

- **Perfil da instituição** — oito declarações que a própria resolução
  condiciona (participa da RSFN? contrata nuvem no exterior? tem comitê de
  risco?). Cada resposta "não" marca os requisitos correspondentes como não
  aplicáveis, com a justificativa citando o artigo — que é o que o art. 23
  manda guardar cinco anos. Uma SCD enxuta deve **131 dos 152**, e sem isso o
  índice mentiria para baixo.
- **Veredito "atende / não atende"** — o Banco Central não lê maturidade de 0
  a 5. O produto traduz, e diz o **motivo**: maturidade abaixo do limiar,
  evidência ausente ou prazo em falta. Prazo estourado derruba para "não
  atende" por mais madura que esteja a prática: o ato ocorreu no prazo ou não
  ocorreu.
- **Prazos e periodicidade** — 20 requisitos têm prazo, e documento anexado
  não prova prazo. O art. 15, § 2º é "até dez dias após a contratação": o
  contrato no acervo não diz quando a comunicação saiu. O Hormos guarda as
  **duas datas** e calcula o veredito. Onde a norma **não fixa número**
  ("periódico", "tempestiva"), o produto não inventa: a instituição declara e
  ele cobra o declarado.
- **Guarda de cinco anos (art. 23)** — não é maturidade de controle, é
  propriedade do documento. E três incisos **não contam da emissão**: o VII
  conta da extinção do contrato, o VIII da implementação e o X da execução do
  teste.
- **Relatório Anual de Segurança Cibernética (art. 8º)** — data-base de 31 de
  dezembro, apresentado ao conselho até 31 de março. As cinco seções do § 1º
  saem dos dados que você já tem. **Enquanto incompleto, ele se declara
  incompleto** e aponta o que falta em cada inciso: o documento é assinado por
  um diretor (art. 7º) e fica cinco anos à disposição do BC, então relatório
  com conteúdo inventado é um problema assinado.
- **Declaração de não ocorrência** — oito pedidos de auditoria terminam com
  "caso não tenham ocorrido… apresentar confirmação formal". A ausência do
  fato é, ela própria, uma obrigação, e sem registrá-la o auditor não
  distingue "nada aconteceu" de "ninguém preencheu". Só vale onde o evento
  **não é obrigatório**: não se declara ausência de teste de intrusão, que o
  art. 22-A exige no mínimo anual.
- **O que anexar** — cada requisito diz qual artefato o prova, derivado da
  resolução.

### iGovTIC-JUD — o índice que o CNJ cobra do Judiciário

Não é "mais um framework", e por isso tem tela própria. A régua é outra: a
nota de cada subitem muda **por ano e por segmento** (TRT, TRE, Superiores,
CNJ), e a evidência é julgada item a item — um subitem declarado sem prova
**zera o item inteiro**. O Hormos cobre o ciclo completo:

- **De onde você vem** — o resultado publicado do seu tribunal acompanha a
  instalação (registro público do CNJ, 92 órgãos, ciclo 2024). Escolha a sigla
  e veja o índice, o nível e quanto faltou em cada pergunta. Sem digitar nada
  e **sem o appliance falar com a internet**: o registro é um arquivo dentro
  da imagem, não uma consulta ao painel.

  **A contrapartida:** como o dado viaja embarcado, ele **não se atualiza
  sozinho**. Quando o CNJ publicar um ciclo novo, o registro correspondente
  vem numa versão nova do produto. Quem precisar antecipar extrai por conta
  própria com `ferramentas/igovtic_extrator/painel_cnj.py`, que fala com o
  painel público do CNJ — essa ferramenta roda fora do appliance, de
  propósito, e não é distribuída na imagem.
- **Ler o ciclo publicado** — a nota de cada pergunta restringe quais subitens
  foram marcados: em ~44% delas a combinação é única, e o Hormos a reconstrói.
  Onde o questionário mudou entre ciclos, ele diz que não é comparável em vez
  de fingir que é.
- **O que o seu SGSI já sustenta** — crosswalk curado com a ISO 27001: se o
  controle está implementado e tem evidência na janela, o subitem é seguro de
  declarar. Se não tem prova, vira aviso, não sugestão.
- **Dossiê para o INTEGRA** — um anexo por item de conformidade, com capa
  gerada, PDF pesquisável, trecho destacado e pré-voo com as regras que o CNJ
  aplicaria.

## Funcionalidades

- **Índice de Segurança Aplicada (ISA)**: o Mapa de Aplicabilidade (Anexo A = ISO/IEC 27002) é o hub —
  correlaciona políticas vinculadas, avaliações ISO 27001 e dos frameworks mapeados (CIS, NIST…)
  em um score 0–100 por controle, por domínio e global (implementação 40% · conformidade 20% ·
  maturidade correlacionada 30% · política vigente 10%)
- **SOA em duas camadas**: seção de **Requisitos do SGSI** (cláusulas 4–10 da ISO 27001, mandatórios —
  prontidão %, status, conformidade, políticas e evidências por requisito) separada dos **93 controles
  do Anexo A** (ISO 27002, com aplicabilidade declarável), com painel de status por framework
  correlacionado (CIS, NIST…) e filtros por status/conformidade/aplicabilidade/política/framework
  (a antiga tela "Mapeamento Cruzado" foi absorvida por esta visão)
- **Evidências por arquivo ou link**: todo ponto de anexo (SOA, avaliações de frameworks, planos,
  NCs e políticas) aceita também um link externo — SharePoint, Google Workspace, GED, repositórios
- **Dashboard Executivo**: maturidade global, heatmap de controles, domínios atual×meta, tendência
- **Framework Engine**: avaliação de maturidade 0-5 (CMMI) em lote, com N/A e evidência por controle
- **Análise de GAP consolidada**: multi-framework, priorizada por criticidade, com criação de plano em 1 clique (GAP→Plano)
- **Planos de Ação**: progresso %, detecção automática de atraso, KPIs por status
- **Gestão de Riscos 5×5**: matriz probabilidade×impacto (Baixo/Médio/Alto/Crítico ≥16), riscos↔controles
- **Cronograma de Auditorias**: auditorias internas (cláusula 9.2), externas (certificação/manutenção)
  e personalizadas, ano a ano — cada auditoria consolida achados (NC Maior/Menor, Observação,
  Oportunidade de Melhoria, Ponto Forte), carta comentário do auditor (texto, arquivo ou link)
  e os registros do SGSI originados nela: NCs, riscos e planos são vinculados à auditoria de origem
  nos próprios formulários; achados do tipo NC convertem-se em NC formal com 1 clique; ao concluir,
  gera o **Relatório de Auditoria (Plano de Ação)** print-friendly para envio aos auditores
- **Relatórios**: 8 relatórios print-friendly (PDF pelo navegador) + exportação CSV —
  executivo, GAP, auditoria, evolução, mapeamento multi-framework, LGPD,
  **iGovTIC-JUD** e o **Relatório Anual do art. 8º da Res. CMN 4.893**
- **Evolução Temporal**: snapshots diários de maturidade por framework
- **SGSI ISO 27001**: Ativos, Riscos, NCs, Planos, SOA, Políticas
- **Saneador Inteligente**: wizard transacional Ativo→Risco→NC→Plano
- **RBAC**: perfis Administrador / Gestor de Risco / Avaliador / Auditor / Leitor (login via Keycloak SSO)
- **API v1** (planos pagos): importar planilha, integrar com outro sistema e puxar dados.
  Autenticação pelo Keycloak embarcado (`client_credentials`), **desligada por padrão** e em
  **porta própria** — ver a seção adiante
- **Logs de Auditoria**: rastreabilidade completa de todas as ações
- **Design Dark Premium**: fusão GRC Platform + SGSI Appliance

## Modo auditor — uma instalação, várias empresas clientes

O Hormos nasceu para **uma** empresa governar o próprio SGSI: é o **modo
auditado**, e continua sendo o padrão. O **modo auditor** acrescenta a camada
de quem presta o serviço para fora — firma de auditoria ou consultoria que
acompanha dez, vinte clientes e precisa ver cada um por dentro e todos por
fora.

Liga-se em **Configurações da Empresa**, e **só por conta Administrador**:
ligar um módulo que cria bancos de dados não é ação de qualquer conta. Exige
**Edição Avançada**, e o gate é lido em tempo de uso — licença que decair
devolve a instalação ao modo auditado sozinha, em vez de deixá-la num modo que
a licença já não cobre.

### Banco por empresa, não compartimento

São dados de empresas que **concorrem entre si**, guardados por um terceiro.
Um vazamento entre dois clientes de uma firma de auditoria não é defeito de
software: é o fim do contrato.

Cada empresa cliente tem o **seu próprio banco de dados**. Não é um
compartimento dentro da mesma base — é outra base, e o PostgreSQL **recusa**
a referência cruzada entre eles. O isolamento deixa de depender de disciplina
de código e passa a ser propriedade do servidor.

### O que acontece ao criar uma empresa

1. Uma base de dados própria é criada, com o prefixo `hormos_cli_` — olhando a
   lista no servidor, fica óbvio o que é dado de cliente.
2. O esquema é replicado do **mesmo DDL que construiu a instalação**.
3. A empresa nasce **vazia**: dados de demonstração não entram em base de
   cliente real.
4. Só então ela é registrada — registro é o que diz "esta empresa existe e
   está pronta". Se a replicação falhar, a base incompleta é removida e nada
   fica registrado.

Leva cerca de um segundo e meio por empresa.

### Visão de fora

Quem acompanha dez clientes não entra em dez telas para saber onde está o
problema. O painel traz um farol por cliente — **bom, atenção, crítico** — com
nota, cobertura, maturidade, riscos altos, NC abertas e planos vencidos.

A nota é **metade cobertura, metade maturidade**: cobertura sozinha premiaria
quem avaliou tudo com nota baixa. Cliente sem avaliação é **"sem dados"**, não
"crítico" — são coisas diferentes, e chamar de crítico quem apenas não começou
seria inventar um diagnóstico. Da mesma forma, cliente cuja base não responde
no momento da consulta aparece como **"indisponível"**: é falha de leitura, não
diagnóstico sobre ele.

Uma faixa fixa no menu diz **em qual cliente você está**. Não é decoração:
editar o cliente errado achando que é outro é o pior erro possível aqui, e ele
não avisa sozinho.

**Desativar não apaga.** O art. 23 da Res. CMN 4.893 manda guardar cinco anos,
e contrato de auditoria costuma mandar mais. Remover uma base é ato de
servidor, deliberado.

## API v1 — desligada por padrão, e em porta própria

Serve para **tirar a planilha do meio**: importar o inventário que já existe,
manter o SGSI em dia a partir de outro sistema e puxar dados para onde a
empresa já olha. Disponível nos planos **Essencial e Avançado**; na Edição
Comunidade o registro do SGSI pela tela continua completo.

Duas decisões sobre ela que mudam a operação:

**Vem desligada.** A API serve ao começo — importação, migração — e depois
costuma ficar esperando parada. Superfície parada é superfície exposta de
graça, então ela nasce desligada e responde `404`: nem o endereço existe.
Liga-se em **Configurações da Empresa → API v1**, por conta Administrador, e
ligar ou desligar fica no rastro de auditoria.

Quem já usava a API antes de atualizar continua com ela ligada: na primeira
subida o Hormos procura chamadas de API no rastro e, achando, mantém o que
estava funcionando.

**Atende na porta 9443**, separada da porta das pessoas:

```
https://SEU-DOMINIO/            → portal (pessoas)
https://SEU-DOMINIO:9443/api/v1 → API (integrações)
```

Isso existe para quem cuida da rede: a API pode ser fechada no firewall,
restringida a uma VPN ou limitada por taxa no equipamento que a empresa já
tem — sem depender de configuração do Hormos e sem que nada disso toque o
acesso das pessoas. Chamar `/api/v1` na porta do portal devolve `404` com um
aviso apontando a porta certa.

Documentação completa, com os exemplos de `curl` e a criação do cliente de
serviço no Keycloak: [`docs/api.md`](docs/api.md).

## Temas (escuro premium ⇄ claro enterprise)

O botão 🌓 no topo alterna entre o tema escuro (padrão, premium) e o claro (enterprise),
com persistência por navegador. A tela de login do Keycloak usa o tema `hormos`
(mesma identidade visual), definido em `keycloak/themes/hormos`.

**Tipografia**: Poppins (títulos), Inter (texto) e IBM Plex Mono (códigos/números) —
**auto-hospedadas** na imagem do portal e no tema do Keycloak: nenhuma chamada
a CDN, o visual é idêntico mesmo em appliance 100% offline.

## SSO, MFA e identidade (Keycloak)

O console administrativo fica em **https://localhost/auth/admin** (usuário/senha:
`KEYCLOAK_ADMIN` / `KEYCLOAK_ADMIN_PASSWORD` do `.env`). O portal (módulo Usuários)
tem um guia com atalhos; os principais caminhos no realm `sgsi`:

| Recurso | Onde configurar |
|---|---|
| MFA / OTP (Google Authenticator) | Authentication → Required actions → *Configure OTP* como Default |
| SSO corporativo (Azure AD, Google, SAML/OIDC) | Identity providers → Add provider |
| Federação LDAP / Active Directory | User federation → Add LDAP provider |
| Política de senhas | Authentication → Policies → Password policy |
| Força bruta | Realm settings → Security defenses |
| Sessões / timeout | Realm settings → Sessions |

### Como o SSO aparece no login

O acesso ao portal pula direto para a tela de login do Hormos (tema `hormos`,
sem tela intersticial). Quando você adiciona um Identity Provider no realm `sgsi`,
o botão **"Entrar com ..."** (Azure AD, Google etc.) aparece automaticamente
**nessa mesma tela**, abaixo do usuário/senha — o usuário escolhe como entrar.

Para pular também o usuário/senha e ir **direto ao IdP corporativo** (SSO total):
Authentication → flow **browser** → no passo *Identity Provider Redirector* →
⚙ config → **Default Identity Provider** = alias do IdP (ex.: `azure-ad`).
O login local continua acessível em caso de contingência via
`https://localhost/auth/realms/sgsi/account`.

## Analista IA embarcado (offline)

Tudo local, nada sai do cliente. O modelo é o **Qwen3-8B** (`qwen3:8b`,
~5,2 GB). O instalador confere a RAM disponível ao Docker e, havendo 8 GB,
baixa o modelo; abaixo disso recusa a IA em vez de instalar um modelo menor
(`OLLAMA_MODEL` no `.env` força outro, por sua conta).

**O raciocínio do modelo fica desligado**, e isso é medição, não preferência.
O Qwen3 "pensa" antes de responder e faz isso por padrão. No mesmo parecer, na
mesma máquina, mudando só essa variável:

| | tempo | resultado |
|---|---|---|
| pensando | **706 s** | pensou 2.394 caracteres para escrever 1.001 |
| sem pensar | **236 s** | escreveu 1.229 caracteres, texto mais completo |

Três vezes mais rápido **e** melhor. Faz sentido: quando o texto chega ao
modelo, o raciocínio já aconteceu — foi o motor determinístico que leu o grafo,
encontrou a reincidência e separou o que tem lastro do que não tem. Ao modelo
resta **redigir**, e redigir não precisa de cadeia de pensamento.

Medido num Apple M1: **cerca de 4 minutos** por parecer de risco com o grafo
inteiro. A geração roda em segundo plano e a tela mostra em que fase está — mas
é bom saber a ordem de grandeza antes de achar que travou.

### Uma geração por vez, e a espera é informada

O portal aceita 12 requisições simultâneas (3 workers × 4 threads). Se quatro
pessoas pedirem parecer juntas, **o appliance atende uma por vez** — de
propósito, em duas camadas.

A primeira é o teto no Ollama (`OLLAMA_NUM_PARALLEL=1`). Sem ele, cada pedido
simultâneo ganha um lugar com cache próprio, reservado **na carga do modelo**,
não quando alguém aparece. Medido lendo o `size` de `/api/ps` logo após a carga,
mesmo modelo, mesma máquina:

| `OLLAMA_NUM_PARALLEL` | modelo residente |
|---|---|
| 4 | **7,86 GB** |
| 1 | **5,94 GB** |

São **1,92 GB** presos para três lugares vazios — 0,64 GB cada. Num appliance
cujo mínimo é 8 GB livres ao Docker, é a diferença entre caber e paginar. E em
CPU paralelizar nem acelera: os mesmos núcleos (já em ~800% com **uma** geração)
passam a ser divididos, e todos esperam mais do que se tivessem sido atendidos
em fila.

A segunda camada existe porque o Ollama enfileira **em silêncio**: o quarto
pedido simplesmente demoraria quatro vezes mais, sem explicação — e espera sem
explicação é indistinguível de travamento. Então o portal mantém a sua própria
fila e diz onde você está:

```
Você é o 2º na fila · início em ~8 min
```

A estimativa sai da **média das últimas 10 gerações reais** daquela instalação,
não de uma constante — uma constante erraria em toda máquina diferente daquela
onde foi medida. A fila aceita 5 esperando; acima disso o pedido é recusado na
hora, porque prometer 40 minutos é pior que recusar.

Duas coisas importam para quem opera:

- **o parecer técnico não espera na fila.** Ele é determinístico, custa ~0,2 s e
  aparece na tela imediatamente, já gravado. Quem entra na fila é só o refino da
  redação pelo LLM. Quem não quiser esperar já tem o conteúdo completo;
- a fila vive **no banco**, não na memória do processo — com 3 workers, estado em
  processo não seria compartilhado. O trinco é de sessão do PostgreSQL, então um
  worker que morra solta o lugar sozinho em vez de entupir a fila.

A correlação semântica usa **embeddings locais** (`nomic-embed-text`, ~300 MB)
com TF-IDF como fallback determinístico — e ela é rápida, não depende do LLM.

**Não há modelo de visão.** Evidência em imagem sem texto legível (catraca, portão,
sala-cofre) é correlacionada pela **descrição que o usuário informa** — determinístico,
instantâneo e sem custo de RAM. O modelo de visão foi testado e removido: somava
3–5 GB ao lado do LLM, levava minutos a frio e entregava descrição genérica, de baixo
valor probatório. Trade ruim para appliance vendido a cliente com hardware modesto.

Dois estágios, sem nenhuma API externa:

1. **Motor semântico** (sempre ativo, zero recursos extras): analisa o texto das políticas
   anexadas (PDF/DOCX/TXT) e as correlaciona com os controles do Anexo A por TF-IDF + léxico
   PT de SI. Gera: cobertura documental por controle, **GAP Documental** na Análise de GAP,
   sugestão de vínculos política⇄SOA em 1 clique, pareceres em Riscos e NCs e sugestões de
   melhoria em Planos.
2. **LLM local opcional** (refina a redação dos pareceres; fatos vêm sempre do motor semântico):
   ```bash
   ./install.sh local --ia    # sobe tudo + baixa o modelo automaticamente (1 comando)
   ```
   Ou manualmente:
   ```bash
   docker compose --profile ia up -d
   docker compose exec ollama ollama pull qwen3:8b   # ~5,2GB, roda em CPU
   ```
   Sem o serviço, tudo funciona com os textos determinísticos (degradação graciosa).
   Modelo configurável via `OLLAMA_MODEL` no `.env`.

   Observações de rede: a `sgsi_internal` é isolada — o serviço `ollama` também entra na
   `sgsi_public` **somente** para o `pull` do modelo; a inferência em si é 100% local.
   Para clientes sem internet, leve o modelo no pacote: na sua máquina, após o pull,
   exporte o volume (`docker run --rm -v sgsi-appliance-core_ollama_data:/d -v $PWD:/out
   alpine tar czf /out/ollama_data.tgz -C /d .`) e restaure no cliente com o comando
   inverso antes do `--profile ia up`.

## Licenciamento (offline, plug and play)

| Edição | Frameworks | Analista IA · GAP · relatórios |
|--------|-----------|-------------------------------|
| **Comunidade** (padrão, sem chave) | ISO 27001/27002 — Anexo A + requisitos das cláusulas 4 a 10 | — |
| **Essencial** | Comunidade + LGPD + CIS Controls v8 | ✔ |
| **Avançado** | Todos (inclui NIST CSF, COBIT e ISO 42001) | ✔ |

A Edição Comunidade é **gratuita e sem prazo**: registra o SGSI por completo em
ISO 27001 — ativos, riscos, controles, políticas, evidências, não conformidades e
planos. O que a licença habilita é a **inteligência sobre esse SGSI** (o Analista
IA, a análise de GAP, os relatórios executivos e a exportação) e os **demais
frameworks**, a começar pela LGPD.

- A chave é assinada em **Ed25519** e validada **100% offline** — nada sai do cliente.
- Aplicar: portal → ⚙ Configurações → **Licença** → colar a chave.
- **A emissão não acontece aqui.** O appliance apenas *verifica*: carrega somente
  a chave pública (`LICENSE_PUBLIC_KEY` no `.env`). A privada vive no licenciador
  do fornecedor, em repositório separado — por isso quem instala o produto não
  consegue emitir a própria licença.
- Frameworks fora do plano aparecem **escurecidos com 🔒** e são bloqueados nas rotas.
- O admin também pode **ativar/desativar** qualquer framework do plano (card fica ⏸ escurecido para os demais usuários).

## Atualização entre versões (v2.x)

Em base existente, reaplique a migração (idempotente — pode rodar quantas vezes quiser):

```bash
docker exec -i sgsi_postgres psql -U $POSTGRES_USER -d $POSTGRES_DB < postgres/04_upgrade.sql
```

Instalações novas já aplicam tudo automaticamente. A migração cobre: escala de risco 3×3 → 5×5,
requisitos ISO 27001 (cláusulas 4–10) no SOA, anexos por link externo e o módulo de Auditorias
(tabelas `auditorias`/`auditoria_achados` + vínculo `auditoria_id` em NCs, riscos e planos).

## Stack

- Flask + PostgreSQL + Caddy + Keycloak + OAuth2 Proxy (Docker)
- LGPD-compliant: dados 100% on-premises

## Instalação

### Linux (Ubuntu/Debian) e macOS

```bash
./install.sh
```

Sem parâmetros, a **instalação é guiada**: o instalador pergunta se o ambiente é
**local ou produção com domínio do cliente** (e já pede domínio/e-mail do certificado),
se quer o **Analista IA** (LLM local) e se é reinstalação do zero. Para automação/CI,
os parâmetros continuam valendo:

```bash
./install.sh local            # instalação local sem perguntas
./install.sh local --ia      # + Analista IA (LLM local, baixa ~1GB)
./install.sh local --reset   # reinstala do zero (APAGA o banco)
```

Pré-requisitos (o instalador verifica e orienta): Docker em execução
(Engine no Linux, Desktop no macOS), Docker Compose (plugin v2 ou
`docker-compose` legado — ambos suportados), `python3` e `openssl`.
No Ubuntu: `sudo apt-get install -y docker.io docker-compose-v2 python3 openssl`
e adicione-se ao grupo (`sudo usermod -aG docker $USER`, relogue).

### Windows

Há três caminhos, e **todos funcionam**. Escolha pelo que você já tem:

**1. Nada instalado — o caminho recomendado.** Clique com o botão direito em
`install.bat` → **Executar como administrador**. Ele instala o WSL2 e o Docker
Engine dentro dele, roda a instalação e ainda confia na CA no repositório do
Windows (Chrome, Edge e Firefox). **Não precisa de Docker Desktop**, e por isso
não há a exigência de licença comercial que ele impõe a empresas maiores.

**2. Já tem Docker Desktop.** Ligue a integração com o WSL em *Settings →
Resources → WSL integration*, abra o Ubuntu e rode `./install.sh`. O `docker`
de dentro do WSL já fala com o daemon do Windows; nada é instalado no Linux.

**3. Já está dentro do WSL com Ubuntu.** `./install.sh` resolve. Duas coisas
que valem saber, porque são do WSL e não do Hormos:

- **Grupo `docker`.** Instalar o Docker Engine não dá acesso ao socket ao seu
  usuário na mesma sessão — credencial de grupo é fixada no login. O instalador
  detecta isso, te põe no grupo e **se reabre já dentro dele**, sem você sair e
  entrar no terminal. Se ainda assim pedir, rode `newgrp docker` e repita.
- **systemd.** O serviço do Docker só sobe sozinho se o systemd estiver ligado,
  e ele **não vem ligado por padrão**. Uma vez só:

  ```bash
  sudo sh -c 'printf "[boot]\nsystemd=true\n" >> /etc/wsl.conf'
  ```

  depois `wsl --shutdown` no PowerShell, reabra o Ubuntu e rode de novo. Sem
  systemd, dá para subir à mão com `sudo service docker start`.

A CA interna é instalada no repositório do **Windows** (é lá que o navegador
roda), não só no do Linux — senão o aviso de certificado continuaria.

**Acesso (todos os sistemas):**
- Portal: <https://localhost> — `http://localhost` e `:8080` redirecionam
- Login/Keycloak: <https://localhost/auth> (mesma origem, um só certificado)
- Credenciais: exibidas ao final do instalador (e guardadas no `.env`)

### Produção com o domínio do cliente (HTTPS automático)

Depois do `install.sh`, um único comando coloca o appliance no domínio do cliente,
com certificado **Let's Encrypt emitido e renovado automaticamente** pelo Caddy:

```bash
./configurar-dominio.sh grc.cliente.com.br
# ou, personalizando o domínio de login e o e-mail do certificado:
./configurar-dominio.sh grc.cliente.com.br auth.grc.cliente.com.br ti@cliente.com.br
```

O assistente faz tudo: ajusta as URLs públicas no `.env` (com cookie seguro),
gera o `caddy/Caddyfile` de produção (portal + Keycloak em HTTPS, HSTS),
expõe as portas 80/443 via `docker-compose.override.yml`, re-renderiza o realm
e **atualiza as redirect URIs do client no Keycloak vivo** via kcadm.

Pré-requisitos no cliente: **2 registros DNS** (`grc.cliente.com.br` e
`auth.grc.cliente.com.br`) apontando para o servidor e **portas 80/443
abertas** para a internet. É idempotente — rode de novo para trocar de domínio;
o acesso local por `https://localhost` continua ativo para contingência
(`http://localhost` e `:8080` redirecionam para lá).

## Atualização do v1.x

O v2.0 é um projeto separado. Para migrar dados do v1.x, exporte
os dados (`pg_dump sgsi`) e importe manualmente nas tabelas compatíveis
(ativos, riscos, ncs, planos, soa, politicas).
