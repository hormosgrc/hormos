# Instalação

O Hormos roda em Docker. O instalador cuida de tudo, inclusive de instalar o
Docker se ele não existir.

## Linux e macOS

```bash
git clone https://github.com/hormosgrc/hormos.git
cd hormos
./install.sh
```

## Windows

> **Recomendamos instalar pelo WSL**, o subsistema Linux que já vem no próprio
> Windows, e **não** pelo Docker Desktop. Os dois funcionam e o Desktop é
> suportado — mas ele exige assinatura comercial para empresas acima de certo
> porte, e o WSL é o caminho que o instalador exercita em ambiente automatizado
> a cada versão.

**Caminho automático.** Baixe o repositório, clique com o botão direito em
`install.bat` e escolha **Executar como administrador**. Ele prepara o WSL2 e o
Docker Engine dentro dele, instala o Hormos em `/opt/hormos` e confia na CA no
repositório do Windows. Se o WSL ainda não existia, ele pede para reiniciar o
Windows e rodar o mesmo arquivo de novo — o progresso não se perde.

**Caminho manual**, comando a comando. No PowerShell como administrador:

```powershell
wsl --install -d Ubuntu
```

Reinicie, abra o Ubuntu, crie o usuário do Linux e então, dentro dele:

```bash
sudo sh -c 'printf "[boot]\nsystemd=true\n" >> /etc/wsl.conf'
# feche o Ubuntu, rode `wsl --shutdown` no PowerShell e reabra

curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
# FECHE E ABRA O TERMINAL — permissão de grupo só vale em sessão nova

docker ps
git clone https://github.com/hormosgrc/hormos.git
cd hormos && ./install.sh
```

O WSL encaminha `localhost` sozinho: o navegador do Windows abre
`https://localhost` sem endereço de máquina virtual.

### Já estou dentro do WSL, ou já tenho Docker Desktop

Também funciona: abra o Ubuntu e rode `./install.sh`. Com Docker Desktop, ligue
antes a integração em *Settings → Resources → WSL integration* — aí o `docker`
do WSL fala com o daemon do Windows e nada é instalado no Linux.

Duas particularidades do WSL que o instalador trata, mas convém conhecer:

- **Grupo `docker`:** entrar no grupo não vale para a sessão em curso, porque
  credencial de grupo é fixada no login. O instalador detecta a falta de
  permissão, te adiciona ao grupo e se reabre já dentro dele. Quando não
  consegue, ele diz o motivo e imprime o comando com o caminho completo —
  `newgrp` abre um shell novo, que começa no `$HOME`, onde o `install.sh` não
  está.
- **systemd:** não vem ligado por padrão no WSL, e sem ele o serviço do Docker
  não sobe sozinho. Sem ele, suba à mão com `sudo service docker start`.

A autoridade certificadora interna é instalada no repositório do **Windows**,
porque é lá que o navegador roda. Instalá-la apenas no Linux não removeria o
aviso de certificado.

## Depois de instalar

Abra <https://localhost>. O instalador cria e confia numa autoridade
certificadora local, então o navegador não reclama do certificado.

Sem chave de licença, o sistema sobe na **Edição Comunidade** — ISO 27001 e
LGPD completos, sem prazo.

## Operação no dia a dia

Você não precisa saber Docker. São três comandos, e funcionam **de qualquer
pasta**:

```bash
docker compose -p sgsi-appliance-core ps       # está no ar?
docker compose -p sgsi-appliance-core stop     # parar (nada é apagado)
docker compose -p sgsi-appliance-core start    # ligar de volta
```

Parar não apaga nada — os dados vivem em volumes, separados dos contêineres — e
o que foi parado **fica parado, mesmo depois de reiniciar a máquina**, até
alguém mandar ligar.

| Contêiner | O que é |
|---|---|
| `sgsi_portal` | o Hormos em si |
| `sgsi_postgres` | o banco: é onde os dados vivem |
| `sgsi_keycloak` | login, SSO e MFA |
| `sgsi_caddy` | a entrada HTTPS |
| `sgsi_oauth2_portal` | o porteiro entre a entrada e o portal |
| `sgsi_configurator` | aplica domínio e certificado próprios |
| `sgsi_ollama` | o Analista IA, se instalado |

Para acompanhar o que o sistema faz (saia com `Ctrl+C`):

```bash
docker compose -p sgsi-appliance-core logs -f --tail=100 sgsi-portal
```

**No Windows, depois de reiniciar:** o WSL não roda em segundo plano sozinho.
Se o `https://localhost` não responder, abra o aplicativo Ubuntu uma vez — o
Docker sobe junto e os contêineres voltam.

O guia completo, com capturas e solução de problemas, está em
<https://hormosgrc.github.io/instalacao.html>.

## Trocar para o seu domínio

Dentro do produto: **Administração → Domínio & Certificado**. Três caminhos:
Let's Encrypt, certificado próprio enviado por upload, ou autoridade
certificadora interna da empresa. Não é preciso mexer em arquivo de
configuração.

## Requisitos

**Sem o Analista IA:** 2 GB de RAM livres ao Docker, 4 GB de disco, 2 núcleos.
O motor semântico embarcado (correlação por embeddings, GAP, índices e
relatórios) funciona inteiro sem LLM.

**Com o Analista IA:** **8 GB de RAM livres ao Docker** — o que exige um
dispositivo com **12 GB** para avaliação e **16 GB** em produção com várias
pessoas, porque os 8 GB são o que sobra depois do sistema operacional. CPU
Core i5 de 11ª geração / Ryzen 5 com 4 núcleos ou superior; **GPU não é
necessária**. 16 a 20 GB de disco.

Não há versão reduzida da IA: o Hormos usa um único modelo da classe 7–8B para
todos os pareceres. Abaixo de 8 GB o instalador recusa a IA e segue sem ela, em
vez de instalar um modelo menor que devolveria parecer pior com a sua marca.
- Linux, macOS ou Windows com WSL2
