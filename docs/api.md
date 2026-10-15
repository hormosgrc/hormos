# API v1

Serve para tirar a planilha do meio: importar o inventário que já existe,
manter o SGSI em dia a partir de outro sistema e puxar dados para onde a
empresa já olha.

**Disponível nos planos Essencial e Avançado.** Na Edição Comunidade a API
responde `403` — o registro do SGSI pela tela continua completo e gratuito.

## Ela vem DESLIGADA, e numa porta própria

Duas decisões que mudam como você a usa:

**1. Desligada por padrão.** A API serve ao começo — importar a planilha que já
existe, migrar de outro sistema — e depois costuma só esperar parada. Superfície
parada é superfície exposta de graça, então ela nasce desligada e responde
`404`: nem o endereço existe. Liga-se em **Configurações da Empresa → API v1**,
por conta Administrador, e ligar ou desligar fica no rastro de auditoria.

Se você já usava a API antes de atualizar, ela continua ligada: na primeira
subida o Hormos procura chamadas de API no rastro de auditoria e, achando,
mantém o que estava funcionando. Não é adivinhação — o ator da API é gravado
como `api:<clientId>`.

**2. Porta própria: 9443.** A API não atende na porta das pessoas. O portal fica
em `443` e a API em `9443`, na mesma máquina:

```
https://SEU-DOMINIO/            → portal (pessoas)
https://SEU-DOMINIO:9443/api/v1 → API (integrações)
```

Isso existe para quem cuida da rede: a API pode ser fechada no firewall,
restringida a uma VPN ou limitada por taxa no equipamento que a empresa já
tem — sem depender de configuração do Hormos e sem que nada disso toque o
acesso das pessoas. Chamar `/api/v1` na porta do portal devolve `404` com um
aviso apontando a porta certa.

Em todos os exemplos abaixo, troque `https://SEU-DOMINIO/api/v1` por
`https://SEU-DOMINIO:9443/api/v1`. O endereço do **token** continua no portal
(`/auth/...`), porque quem emite token é o Keycloak, não a API.

---

## Autenticação

O Hormos não inventou autenticação para a API. Ela usa o **Keycloak que já
vem no appliance**, pelo fluxo `client_credentials` do OAuth2 — o padrão para
máquina falando com máquina. Não há usuário, senha de pessoa nem navegador
envolvidos.

### 1. Crie um cliente de serviço

No console do Keycloak (`https://SEU-DOMINIO/auth`), no realm **sgsi**:

1. **Clients → Create client**
   - *Client ID*: um nome que identifique a integração, ex. `integracao-rh`
   - *Client authentication*: **On**
   - *Authentication flow*: desmarque tudo e deixe só **Service accounts roles**
2. Em **Credentials**, copie o *Client secret*
3. Em **Roles**, crie dois papéis: `api-leitura` e `api-escrita`
4. Em **Service accounts roles → Assign role**, conceda à conta de serviço
   apenas o que a integração precisa

> **Dê só leitura quando for só leitura.** A maioria das integrações apenas
> consulta ou apenas despeja dado. Token de escrita vazado é estrago muito
> maior que token de leitura vazado.

O *Client ID* aparece nos **Logs de Auditoria** como `api:integracao-rh`, em
toda alteração feita por ele. Escolha um nome que diga o que a integração é.

### 2. Peça um token

```bash
curl -X POST "https://SEU-DOMINIO/auth/realms/sgsi/protocol/openid-connect/token" \
  -d grant_type=client_credentials \
  -d client_id=integracao-rh \
  -d client_secret=SEU_SEGREDO
```

Resposta:

```json
{ "access_token": "eyJhbGciOiJSUzI1NiIs...", "expires_in": 300, "token_type": "Bearer" }
```

**O token vale 5 minutos.** Não guarde: qualquer biblioteca de OAuth2 —
Python, Node, Postman, n8n, Power Automate — renova sozinha. Tempo curto é
proposital: token vazado tem validade curta.

### 3. Use o token

```bash
curl -H "Authorization: Bearer SEU_TOKEN" \
     "https://SEU-DOMINIO:9443/api/v1/saude"
```

---

## Comece por `/saude`

```
GET /api/v1/saude
```

```json
{
  "ok": true,
  "versao_api": "v1",
  "cliente": "integracao-rh",
  "papeis": ["api-leitura"],
  "pode_ler": true,
  "pode_escrever": false,
  "plano": "Avançado",
  "instancia": "9DBEFA709228"
}
```

Numa chamada você confirma que o token vale, que o plano libera a API e que
papéis tem — **antes** de escrever o primeiro registro. Sem isso, o primeiro
erro apareceria no meio de uma importação.

---

## Recursos

| Recurso | Ler | Escrever | Identidade |
|---|---|---|---|
| `ativos` | ✓ | ✓ | `IA-0007` |
| `riscos` | ✓ | ✓ | `RC-0008` |
| `ncs` | ✓ | ✓ | `NC-0012` |
| `planos` | ✓ | ✓ | `PA-0042` |
| `evidencias` | ✓ | — | UUID |

A API fala por **código de negócio**, não por id de banco. É o mesmo código
que aparece na tela e na sua planilha.

---

## Leitura

### Listar

```
GET /api/v1/ativos
GET /api/v1/ativos?criticidade=Alta&status=Ativo
GET /api/v1/riscos?busca=backup
GET /api/v1/planos?atrasado=1
GET /api/v1/ncs?pagina=2&por_pagina=100
```

```json
{
  "dados": [ { "codigo": "IA-0001", "nome": "...", "criticidade": "Alta" } ],
  "pagina": 1,
  "por_pagina": 50,
  "total": 137,
  "total_paginas": 3,
  "filtros_aplicados": { "criticidade": "Alta" }
}
```

`por_pagina` vai até **200**; valor maior é reduzido em silêncio.
`filtros_aplicados` mostra o que o servidor de fato entendeu — se um filtro
seu não aparecer ali, ele foi ignorado por não existir.

**Busca** (`?busca=`) é textual, parcial e insensível a maiúsculas, sobre os
campos principais de cada recurso.

**Filtros especiais**, que não são igualdade de campo:

| Recurso | Filtro | O que traz |
|---|---|---|
| `planos` | `atrasado=1` | Prazo vencido e ainda aberto |
| `planos` | `aberto=1` | Nem implementado nem cancelado |
| `planos` | `sem_responsavel=1` | Sem dono definido |
| `evidencias` | `vencida=1` | Fora do prazo de validade |
| `evidencias` | `vigente=1` | Dentro do prazo |

### Um item

```
GET /api/v1/riscos/RC-0008
```

Devolve o objeto direto, ou `404` com o motivo em português.

---

## Escrita

Requer o papel **`api-escrita`**.

### Criar um

```bash
curl -X POST "https://SEU-DOMINIO:9443/api/v1/ativos" \
  -H "Authorization: Bearer SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
        "nome": "Servidor de arquivos do RH",
        "natureza": "Suporte",
        "criticidade": "Alta",
        "dono": "ti@empresa.com"
      }'
```

```json
{ "codigo": "IA-0042" }
```

**O código é atribuído pelo Hormos**, nunca enviado por você. Mandar `codigo`
no corpo é recusado — aceitar produziria colisão silenciosa entre integrações.

### Criar em lote

Mande uma **lista** em vez de um objeto. É o caminho da migração de planilha.

```bash
curl -X POST "https://SEU-DOMINIO:9443/api/v1/ativos" \
  -H "Authorization: Bearer SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '[ {"nome":"Notebook Diretoria","natureza":"Suporte"},
        {"nome":"Base de clientes","natureza":"Primário"},
        {"criticidade":"Alta"} ]'
```

```json
{
  "criados": ["IA-0043", "IA-0044"],
  "falhas": [ { "indice": 2, "erros": ["Campo obrigatório ausente ou vazio: nome."] } ],
  "total_enviado": 3,
  "total_criado": 2
}
```

> **O lote NÃO é transacional, de propósito.** Se a linha 47 de 500 estiver
> errada, as outras 499 entram. Abortar tudo obrigaria você a corrigir uma
> linha e reenviar 500; assim você corrige 1 e reenvia 1. A resposta diz o
> índice exato e o motivo de cada falha.

Limite de **500 itens por lote**. Acima disso, `413` — divida em partes.

### Atualizar

```bash
curl -X PATCH "https://SEU-DOMINIO:9443/api/v1/planos/PA-0042" \
  -H "Authorization: Bearer SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"progresso": 80, "status": "Em Andamento"}'
```

```json
{
  "atualizado": "PA-0042",
  "campos": ["progresso", "status"],
  "mudancas": [ { "campo": "progresso", "de": 40, "para": 80 } ]
}
```

É **`PATCH`**, não `PUT`: só os campos enviados mudam. `PUT` significaria
"substitua o recurso inteiro", e um campo esquecido apagaria o valor sem você
perceber.

### Não existe `DELETE`

Fora da v1 por decisão de produto. Exclusão por API é o jeito mais rápido de
apagar o SGSI inteiro com um laço errado. A exclusão existe na tela, com
confirmação — e com recriação a partir dos Logs de Auditoria.

---

## Erros

Sempre JSON, com o motivo em português.

| Código | Quando |
|---|---|
| `400` | Corpo ausente, não-JSON, ou sem campo gravável |
| `401` | Token ausente, malformado, expirado ou de outro emissor |
| `403` | Papel insuficiente, **ou a Edição não inclui a API** |
| `404` | Recurso ou item inexistente |
| `413` | Lote acima de 500 itens |
| `422` | Item recusado na validação |
| `429` | Acima de 600 requisições por minuto |

```json
{ "erro": "criticidade: 'Altíssima' não é um valor válido. Use um de: Alta, Média, Baixa." }
```

**Campo desconhecido é recusado, não ignorado.** Se você escrever
`criticidad` sem o "e", recebe erro — em vez de achar que importou e descobrir
o buraco meses depois.

---

## Limite de uso

**600 requisições por minuto por cliente**, contando leitura e escrita. A
chave é o *Client ID*, então uma integração descontrolada não derruba as
outras nem os usuários na tela.

Ao estourar, `429` com o cabeçalho `Retry-After` dizendo quantos segundos
esperar.

---

## Tudo fica no log

Toda escrita pela API entra nos **Logs de Auditoria** como
`api:SEU-CLIENT-ID`, com o valor anterior e o novo de cada campo. É o mesmo
rastro das alterações feitas na tela — e, como elas, registros excluídos podem
ser recriados a partir do log.

Para quem audita, isso responde a pergunta que importa: *quem mudou isso, e do
que para o quê.*
