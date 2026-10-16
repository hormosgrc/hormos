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

Baixe o repositório, clique com o botão direito em `install.bat` e escolha
**Executar como administrador**.

O instalador prepara o WSL2 e o Docker Engine dentro dele. Não é necessário
Docker Desktop — e por isso não há a exigência de licença comercial que ele
impõe a empresas maiores.

### Já estou dentro do WSL, ou já tenho Docker Desktop

Também funciona: abra o Ubuntu e rode `./install.sh`. Com Docker Desktop, ligue
antes a integração em *Settings → Resources → WSL integration* — aí o `docker`
do WSL fala com o daemon do Windows e nada é instalado no Linux.

Duas particularidades do WSL que o instalador trata, mas convém conhecer:

- **Grupo `docker`:** entrar no grupo não vale para a sessão em curso, porque
  credencial de grupo é fixada no login. O instalador detecta a falta de
  permissão, te adiciona ao grupo e se reabre já dentro dele. Se precisar à
  mão: `newgrp docker`.
- **systemd:** não vem ligado por padrão no WSL, e sem ele o serviço do Docker
  não sobe sozinho. Habilite uma vez com
  `sudo sh -c 'printf "[boot]\nsystemd=true\n" >> /etc/wsl.conf'`, rode
  `wsl --shutdown` no PowerShell e reabra o Ubuntu.

A autoridade certificadora interna é instalada no repositório do **Windows**,
porque é lá que o navegador roda. Instalá-la apenas no Linux não removeria o
aviso de certificado.

## Depois de instalar

Abra <https://localhost>. O instalador cria e confia numa autoridade
certificadora local, então o navegador não reclama do certificado.

Sem chave de licença, o sistema sobe na **Edição Comunidade** — ISO 27001 e
LGPD completos, sem prazo.

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
