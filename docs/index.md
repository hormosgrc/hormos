# Hormos

**Appliance de GRC auto-hospedado.** Roda inteiro na infraestrutura da sua
empresa: ISO/IEC 27001, LGPD, CIS Controls v8, NIST CSF, COBIT 2019 e ISO 42001,
mais a **Res. CMN 4.893 do Banco Central** e o **iGovTIC-JUD** do CNJ, com
correlação entre as normas e inteligência artificial local — **nenhum dado
do seu SGSI sai da sua rede**.

> **ὅρμος** (*hórmos*), do grego: o ancoradouro abrigado onde o navio para no
> meio da viagem — e também o colar, contas presas num mesmo fio. Os dois
> sentidos descrevem o produto. Ninguém certifica — **nem se mantém
> certificado** — da noite para o dia: a conformidade não é um destino que se
> alcança e encerra, é uma travessia que continua depois do certificado. O
> Hormos é a parada segura ao longo dela, com ativo, risco, controle,
> evidência e plano num fio só. O símbolo é esse fio, com duas contas.

<p align="center">
  <img src="img/hormos-cadeia.svg" alt="Da estratégia à evidência — a cadeia do SGSI" width="100%">
</p>

## Documentação

- **[Como o Hormos pensa](modelo.md)** — o modelo: o que é cada coisa, por que
  a norma exige, e como uma puxa a outra.
- **[Guia de cada tela](telas.md)** — o que você faz, o que o sistema faz
  sozinho e o que ele vai cobrar de você.
- **[Instalação](instalacao.md)** — Linux, macOS e Windows.
- **[API v1](api.md)** — importar planilha, integrar com outro sistema e puxar
  dados. Autenticação pelo Keycloak que já vem no appliance. Vem **desligada**
  e atende em **porta própria** (9443), para o firewall da empresa poder
  tratá-la sem tocar no acesso das pessoas.

## Edições

| | Comunidade | Essencial | Avançado |
|---|---|---|---|
| Preço | **gratuito, sem prazo** | licenciado | licenciado |
| ISO/IEC 27001 (Anexo A + requisitos) | ✓ | ✓ | ✓ |
| LGPD (RoPA, prazos legais, Encarregado) | — | ✓ | ✓ |
| CIS Controls v8 | — | ✓ | ✓ |
| NIST CSF · COBIT · ISO 42001 | — | — | ✓ |
| **BACEN Res. CMN 4.893** · iGovTIC-JUD | — | — | ✓ |
| **Modo auditor** (carteira de clientes) | — | — | ✓ |
| Correlação entre normas | — | ✓ | ✓ |
| Importação de framework próprio | — | — | ✓ |
| Atualização de catálogo normativo | — | ✓ | ✓ |

A **Edição Comunidade** não é demonstração nem versão limitada no tempo: é um
SGSI ISO 27001 completo, para uma instância, para sempre, sem cadastro.

O **modo auditor** da Edição Avançada é para quem presta o serviço: uma
instalação atende vários clientes, cada um com **banco de dados próprio** — uma
empresa não enxerga a outra, e o PostgreSQL recusa a referência cruzada entre
as bases. Liga-se em Configurações da Empresa, por conta Administrador.

## Licenciamento

Software **source-available** sob [Elastic License 2.0](https://www.elastic.co/licensing/elastic-license):
o código pode ser lido e auditado, mas não é software livre. É vedado fornecer o
produto como serviço gerenciado a terceiros e contornar a verificação de licença.

## Segurança

Encontrou uma vulnerabilidade? Veja a
[política de segurança](https://github.com/hormosgrc/hormos/blob/main/SECURITY.md).
Não abra issue pública.

---

<small>Estas páginas são a versão web da documentação que já vem embarcada no
produto, em <code>/guia</code>. Ao alterar uma, altere a outra.</small>
