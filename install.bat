@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Hormos - Instalador (Windows)
cd /d "%~dp0"

REM ══════════════════════════════════════════════════════════════════
REM  Hormos — instalador do Windows.
REM
REM  Estratégia: NÃO usa Docker Desktop. Instala o WSL2 (subsistema
REM  Linux do proprio Windows) e, dentro dele, o Docker Engine +
REM  Compose (open source, sem restricao de licenca comercial).
REM  O WSL2 encaminha "localhost" automaticamente, entao o navegador
REM  do Windows acessa https://localhost normalmente.
REM
REM  Basta dar DUPLO CLIQUE neste arquivo.
REM ══════════════════════════════════════════════════════════════════

REM ── Auto-elevacao (UAC): WSL e o repositorio de certificados exigem admin ──
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo  Solicitando privilegios de administrador...
    REM  Pela variavel de ambiente, e nao por "-FilePath '%~f0'". Entre aspas
    REM  simples, um apostrofo no caminho fecha a string antes da hora — e
    REM  C:\Users\O'Brien\... e um caminho perfeitamente comum. Em $env: o
    REM  valor e uma string e nao passa por parsing nenhum.
    set "EU=%~f0"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath $env:EU -Verb RunAs"
    exit /b
)

echo.
echo  ═══════════════════════════════════════════════
echo    Hormos — Instalador (Windows / WSL2)
echo  ═══════════════════════════════════════════════
echo.

REM ── Retomada automatica apos o reinicio ───────────────────────────
REM  O Windows EXIGE reinicio depois de instalar o WSL, e isso nao se
REM  contorna: os recursos ficam em "EnablePending" e so passam a valer no
REM  proximo boot. Seguir dali da erro de PERMISSAO em tudo o que vem
REM  depois — foi o que aconteceu numa instalacao real, e a mensagem de erro
REM  nao diz a causa.
REM
REM  A tarefa e apagada JA NO COMECO desta execucao, nao so no fim: se a
REM  instalacao falhar depois do reinicio, ela nao fica voltando a cada
REM  logon para sempre. Uma tentativa por agendamento — o que o "RunOnce"
REM  do Windows faz — mas como tarefa agendada com RunLevel Highest, para
REM  voltar JA elevada e nao parar num UAC com a pessoa longe do teclado.
set "DETECTA=%~dp0scripts\estado-wsl.ps1"
set "RETOMA=%~dp0scripts\retomar-instalacao.ps1"
for %%F in ("%DETECTA%" "%RETOMA%") do (
    if not exist "%%~F" (
        echo  X Arquivo ausente: %%~nxF
        echo    A pasta foi descompactada por completo?
        pause
        exit /b 1
    )
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%RETOMA%" -Acao consumir
set "RETOMADA=0"
if %errorLevel% equ 10 (
    set "RETOMADA=1"
    echo  Retomando a instalacao apos o reinicio...
    echo.
)

REM ── 1. O WSL esta instalado E ATIVO? ──────────────────────────────
REM  `where wsl` nao prova nada: o wsl.exe acompanha o Windows mesmo sem o
REM  WSL instalado, e `wsl --status` pode responder com os recursos ainda
REM  pendentes de reinicio. Era essa a deteccao daqui, e e por isso que o
REM  instalador seguia em frente numa maquina que ainda nao podia rodar nada.
echo  [1/6] Verificando o WSL...

REM  A deteccao mora em scripts\estado-wsl.ps1 — PowerShell de verdade, em
REM  arquivo, porque embutido aqui viraria um `for /f` com tres niveis de
REM  escape de aspas que ninguem revisa. Sem ele nao da para distinguir
REM  "falta reiniciar" de "nao esta instalado", entao ausencia e erro.

REM  O codigo de saida e lido para uma variavel ANTES de qualquer outra
REM  coisa: `set` bem-sucedido zera o %%errorLevel%%, e um segundo `if`
REM  comparando %%errorLevel%% depois do primeiro ja testaria outro valor.
powershell -NoProfile -ExecutionPolicy Bypass -File "%DETECTA%" -Checar plataforma
set "ESTADO_WSL=%errorLevel%"

if "%ESTADO_WSL%"=="0" (
    echo  ✓ WSL instalado e ativo.
    goto :checar_distro
)
if "%ESTADO_WSL%"=="1" (
    echo  ! O WSL ja foi instalado, mas so passa a valer depois de reiniciar.
    goto :pedir_reinicio
)

echo       WSL nao encontrado — instalando...
REM  --no-distribution instala SO a plataforma. A distribuicao fica para o
REM  passo 2, depois do reinicio: instala-la agora exigiria o WSL ja ativo,
REM  e ele ainda nao esta.
wsl --install --no-distribution
if %errorLevel% neq 0 (
    echo.
    echo  X Falha ao instalar o WSL.
    echo.
    echo    Causa mais comum: virtualizacao desabilitada na BIOS/UEFI.
    echo    Habilite "Intel VT-x" ou "AMD-V" e rode este instalador de novo.
    echo.
    pause
    exit /b 1
)
echo  ✓ WSL instalado.
goto :pedir_reinicio

:pedir_reinicio
echo.
REM  Dizer "precisa reiniciar" sem dizer POR QUE e inutil para quem acabou
REM  de reiniciar — e esse caso aconteceu numa instalacao real. O estado cru
REM  vai para a tela sempre, antes da pergunta.
echo  ── estado desta maquina ───────────────────────
powershell -NoProfile -ExecutionPolicy Bypass -File "%DETECTA%" -Checar diagnostico
echo  ───────────────────────────────────────────────

REM  Se ESTA execucao ja e a retomada de um reinicio, pedir outro seria um
REM  laco: reinicia, volta, pede de novo, para sempre. Quando reiniciar nao
REM  resolve, a resposta honesta e parar e mostrar o estado, nao insistir.
if "%RETOMADA%"=="1" (
    echo.
    echo  ═══════════════════════════════════════════════
    echo   REINICIAR NAO RESOLVEU
    echo.
    echo   Esta execucao JA e a retomada de um reinicio, e o
    echo   WSL continua sem conseguir rodar. Pedir outro
    echo   reinicio nao vai mudar nada.
    echo.
    echo   Mande o quadro de estado acima para o suporte:
    echo   https://hormosgrc.github.io/instalacao.html
    echo  ═══════════════════════════════════════════════
    echo.
    pause
    exit /b 1
)

echo.
echo  ═══════════════════════════════════════════════
echo   O Windows precisa REINICIAR para concluir
echo.
echo   Posso agendar a continuacao: a maquina reinicia
echo   e a instalacao recomeca de onde parou, sozinha,
echo   sem voce precisar fazer nada.
echo  ═══════════════════════════════════════════════
echo.
set "RESP="
set /p "RESP=  Reiniciar agora e continuar automaticamente? [S/n]: "
if /i "%RESP%"=="n" goto :reinicio_manual

REM  Agendar pelo script, e nao por `schtasks /tr "\"%~f0\""`: o cmd nao
REM  processa \" como escape, e o caminho mais comum do usuario e o pior caso
REM  possivel — quem baixa o zip duas vezes recebe "hormos-main (1)" do
REM  proprio Windows, com espaco E parenteses.
powershell -NoProfile -ExecutionPolicy Bypass -File "%RETOMA%" -Acao agendar -Script "%~f0"
if %errorLevel% neq 0 (
    echo  ! Nao consegui agendar a continuacao automatica.
    goto :reinicio_manual
)
echo.
echo  ✓ Continuacao agendada.
echo.
REM  O `shutdown` e emitido DEPOIS desta tecla, nao antes. Antes, a
REM  mensagem dizia "feche esta janela e rode shutdown /a" para cancelar —
REM  mas fechando a janela nao sobra onde rodar o comando. Assim, fechar a
REM  janela agora simplesmente nao reinicia nada, e o agendamento fica de
REM  pe: reiniciando a mao mais tarde, a instalacao continua igual.
echo    Pressione qualquer tecla para REINICIAR agora.
echo    Ou feche esta janela: nada reinicia, e a instalacao continua
echo    sozinha no proximo reinicio que voce fizer.
pause >nul
shutdown /r /t 5 /c "Hormos: reinicio para concluir a instalacao do WSL"
exit /b 0

:reinicio_manual
echo.
echo  ═══════════════════════════════════════════════
echo   REINICIE O WINDOWS e execute este instalador
echo   novamente. O progresso ate aqui esta salvo —
echo   ele nao reinstala o que ja existe.
echo  ═══════════════════════════════════════════════
echo.
pause
exit /b 0

:checar_distro
wsl --set-default-version 2 >nul 2>&1

REM ── 2. Distribuicao Ubuntu ────────────────────────────────────────
REM  Aqui ha DOIS estados que nao se confundem, e tratar os dois como um
REM  so foi o defeito que apareceu em campo:
REM
REM    REGISTRADA — o `wsl --install -d` ja rodou e a distro aparece em
REM                 `wsl -l -q`, mas o sistema de arquivos ainda nao foi
REM                 extraido. Baixar de novo joga fora o download.
REM    PRONTA     — executa comando como root e responde.
REM
REM  Antes, um unico `wsl -d Ubuntu -- true` respondia "nao existe" para
REM  uma distro que EXISTIA e so faltava inicializar — e o instalador
REM  baixava o Ubuntu inteiro outra vez. Agora pergunta-se primeiro se
REM  esta registrada (barato, nao inicializa nada) e so depois se roda.
set "DISTRO=Ubuntu"
set "ACHADA="
set "INSTALEI_AGORA=0"
for /f "usebackq delims=" %%R in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%DETECTA%" -Checar distro -Nome Ubuntu`) do set "ACHADA=%%R"

if defined ACHADA (
    REM  Volta o nome REAL: quem tem "Ubuntu-24.04" tem Ubuntu, e seguimos
    REM  com o nome dele. Instalar "Ubuntu" ao lado seria baixar uma segunda
    REM  distribuicao para fazer o que a primeira ja faz.
    set "DISTRO=!ACHADA!"
    echo  [2/6] Distribuicao !ACHADA! ja instalada — nao vou baixar de novo.
) else (
    echo  [2/6] Instalando a distribuicao %DISTRO%...
    wsl --install -d %DISTRO% --no-launch
    if !errorLevel! neq 0 (
        echo  X Nao foi possivel instalar o %DISTRO%.
        pause
        exit /b 1
    )
    echo  ✓ %DISTRO% baixado.
    REM  O primeiro uso e concluido logo abaixo, DEPOIS de localizar o
    REM  lancador: numa instalacao nova o ubuntu.exe so passa a existir agora,
    REM  porque ele vem junto com o pacote da distribuicao. Procurar antes
    REM  disso nao acharia nada.
    set "INSTALEI_AGORA=1"
)

REM  Primeira inicializacao: extrai o sistema de arquivos. Pode levar um
REM  minuto e parecer travado, entao se anuncia.
REM  Localiza o LANCADOR da distribuicao. Ele e o que conclui o primeiro uso
REM  ("ubuntu.exe install --root"), e e o passo que o `wsl --install
REM  --no-launch` deixa PENDENTE — era o buraco desta instalacao. Sem ele a
REM  distro fica registrada e incapaz de executar, e quem abre o aplicativo
REM  "Ubuntu" cai no "Enter new UNIX username".
REM  O nome do executavel varia com a versao, entao procura-se.
set "LANCADOR="
REM  Bloco aninhado, e nao `if not defined X where ... ^&^& set`: ali o ^&^&
REM  liga no `where`, e quando o `if` nao executa nada o errorLevel e o que
REM  sobrou de antes — o `set` rodaria do mesmo jeito, gravando um lancador
REM  que nao existe.
for %%L in (ubuntu.exe ubuntu2404.exe ubuntu2204.exe ubuntu2004.exe) do (
    if not defined LANCADOR (
        where %%L >nul 2>&1
        if !errorLevel! equ 0 set "LANCADOR=%%L"
    )
)

REM  Instalacao NOVA: conclui o primeiro uso agora, sem esperar a escada de
REM  conserto abaixo. E o caminho documentado — `install --root` termina a
REM  instalacao sem pedir usuario nenhum, deixando so o root (o usuario da
REM  pessoa e criado no passo 3). E a AUSENCIA deste passo que deixava a
REM  distro registrada e incapaz de executar.
if "%INSTALEI_AGORA%"=="1" if defined LANCADOR (
    echo       Concluindo o primeiro uso ^(!LANCADOR! install --root^)...
    !LANCADOR! install --root
    wsl --shutdown
    timeout /t 3 /nobreak >nul
)

echo       Inicializando o %DISTRO%...
set "TENTATIVA=0"

:tentar_iniciar
set /a TENTATIVA+=1
REM  Saida na TELA: a mensagem do wsl.exe e a unica pista do motivo, e foi
REM  manda-la para nul que me obrigou a adivinhar a causa — e eu adivinhei
REM  errado, culpei reinicio pendente numa maquina sem reinicio pendente.
wsl -d %DISTRO% -u root -- true
if %errorLevel% equ 0 goto :distro_pronta

if %TENTATIVA% equ 1 (
    REM  Degrau 1 — o conserto mais relatado para Wsl/Service/E_UNEXPECTED e
    REM  `wsl --update` seguido de `wsl --shutdown`. Barato e nao destroi nada.
    echo.
    echo       Nao respondeu. Atualizando o WSL e tentando de novo...
    wsl --update
    wsl --shutdown
    timeout /t 3 /nobreak >nul
    goto :tentar_iniciar
)

if %TENTATIVA% equ 2 (
    REM  Degrau 2 — concluir o primeiro uso pelo lancador. E o passo que
    REM  faltava: `install --root` termina a instalacao SEM pedir usuario, e
    REM  deixa so o root. O usuario da pessoa e criado no passo 3, logo abaixo.
    if defined LANCADOR (
        echo.
        echo       Concluindo o primeiro uso da distribuicao ^(!LANCADOR!^)...
        !LANCADOR! install --root
        wsl --shutdown
        timeout /t 3 /nobreak >nul
    ) else (
        echo       Nao encontrei o lancador da distribuicao.
    )
    goto :tentar_iniciar
)

if %TENTATIVA% equ 3 (
    REM  Degrau 3 — a esta altura a VHD da distro esta corrompida, e nenhum
    REM  conserto a recupera: e apagar e refazer. Por isso PERGUNTA — isto
    REM  destroi o sistema de arquivos do Ubuntu, sem lixeira.
    echo.
    echo  ═══════════════════════════════════════════════
    echo   A distribuicao %DISTRO% esta danificada
    echo.
    echo   Nem a atualizacao do WSL nem a conclusao do
    echo   primeiro uso resolveram. Isso indica disco da
    echo   distribuicao corrompido, e o unico conserto e
    echo   apagar e instalar de novo.
    echo.
    echo   ATENCAO: isso APAGA o Ubuntu e tudo dentro dele,
    echo   sem lixeira. Se o Hormos ja estava instalado ali,
    echo   os dados dele vao junto.
    echo  ═══════════════════════════════════════════════
    echo.
    set "RESP="
    set /p "RESP=  Apagar o %DISTRO% e instalar de novo? [s/N]: "
    if /i "!RESP!"=="s" (
        wsl --unregister %DISTRO%
        wsl --install -d %DISTRO% --no-launch
        if defined LANCADOR !LANCADOR! install --root
        wsl --shutdown
        timeout /t 3 /nobreak >nul
        goto :tentar_iniciar
    )
    echo       Nao apaguei nada.
)

echo.
echo  ! O %DISTRO% esta registrado mas nao consegue executar, e os tres
echo    consertos automaticos nao resolveram.
goto :pedir_reinicio

:distro_pronta
echo  ✓ %DISTRO% pronto.

REM ── 3. O usuario do Linux ─────────────────────────────────────────
REM  POR QUE ISTO EXISTE: a distribuicao e instalada com --no-launch, entao
REM  nasce SEM usuario nenhum. Quem abrir o aplicativo "Ubuntu" depois cai
REM  num "Enter new UNIX username" — e todo o guia de operar o appliance manda
REM  abrir o Ubuntu para rodar `docker compose`. A instalacao terminava e
REM  deixava a pessoa trancada fora do proprio terminal.
REM
REM  O appliance roda como root e nao precisa deste usuario. Ele existe para
REM  a PESSOA, e e por isso que a senha e gerada aqui e mostrada no fim: quem
REM  instala nao tem como inventar uma no prompt do Ubuntu nem recuperar
REM  depois.
echo  [3/7] Criando o usuario do Ubuntu...
set "USUARIO_WSL=hormos"

REM  `id` antes de criar: rodar o instalador duas vezes nao pode trocar a
REM  senha de um usuario que a pessoa ja anotou.
wsl -d %DISTRO% -u root -- bash -c "id %USUARIO_WSL% >/dev/null 2>&1 || useradd -m -s /bin/bash -G sudo %USUARIO_WSL%"
if %errorLevel% neq 0 (
    echo  X Nao foi possivel criar o usuario %USUARIO_WSL% no %DISTRO%.
    pause
    exit /b 1
)

REM  /dev/urandom e nao openssl: numa imagem minima o openssl pode nao estar
REM  la, e descobrir isso em campo custa uma instalacao. Sem / + = na senha,
REM  que atrapalham quem vai digitar a mao.
wsl -d %DISTRO% -u root -- bash -c "test -s /root/.senha-ubuntu || { tr -dc A-Za-z0-9 </dev/urandom | head -c 14 > /root/.senha-ubuntu; chmod 600 /root/.senha-ubuntu; }; echo %USUARIO_WSL%:$(cat /root/.senha-ubuntu) | chpasswd"
if %errorLevel% neq 0 (
    echo  X Nao foi possivel definir a senha do %USUARIO_WSL%.
    pause
    exit /b 1
)

REM  default no wsl.conf: sem isto, abrir o aplicativo "Ubuntu" entra como
REM  root, e a pessoa opera tudo como root sem saber que esta.
wsl -d %DISTRO% -u root -- bash -c "grep -q '^\[user\]' /etc/wsl.conf 2>/dev/null || printf '[user]\ndefault=%USUARIO_WSL%\n' >> /etc/wsl.conf"
REM  Alem do wsl.conf, o lancador tem o caminho proprio e documentado para
REM  isto. Os dois juntos porque o wsl.conf e lido no boot da distro e o
REM  lancador grava no registro do Windows — e qual dos dois vale depende da
REM  versao do WSL. Fazer os dois custa uma linha.
if defined LANCADOR %LANCADOR% config --default-user %USUARIO_WSL% >nul 2>&1
echo  ✓ Usuario %USUARIO_WSL% criado ^(a senha aparece no fim^).

REM ── 4. systemd (necessario para o servico do Docker subir sozinho) ─
echo  [4/7] Habilitando systemd no WSL...
wsl -d %DISTRO% -u root -- bash -c "grep -q '^systemd=true' /etc/wsl.conf 2>/dev/null || printf '[boot]\nsystemd=true\n' >> /etc/wsl.conf"
wsl --shutdown
timeout /t 3 /nobreak >nul

REM ── 5. Docker Engine + Compose DENTRO do WSL ──────────────────────
echo  [5/7] Verificando o Docker dentro do WSL...
wsl -d %DISTRO% -u root -- bash -c "command -v docker >/dev/null 2>&1"
if %errorLevel% equ 0 (
    echo  ✓ Docker ja instalado no WSL.
) else (
    echo       Instalando o Docker Engine ^(open source, sem licenca comercial^)...
    wsl -d %DISTRO% -u root -- bash -c "curl -fsSL https://get.docker.com | sh"
    if !errorLevel! neq 0 (
        echo  ✖ Falha ao instalar o Docker no WSL. Verifique a conexao com a internet.
        pause
        exit /b 1
    )
    echo  ✓ Docker Engine instalado.
)
wsl -d %DISTRO% -u root -- bash -c "systemctl enable --now docker >/dev/null 2>&1 || service docker start >/dev/null 2>&1; true"

REM  Grupo docker so DEPOIS de instalar o Docker, porque e a instalacao dele
REM  que cria o grupo. Sem isto a pessoa precisa de sudo em todo comando, e o
REM  guia de operacao nao usa sudo em nenhum.
wsl -d %DISTRO% -u root -- bash -c "getent group docker >/dev/null || groupadd docker; usermod -aG docker %USUARIO_WSL%"

REM ── 6. Copia o projeto para dentro do WSL e instala ───────────────
echo  [6/7] Preparando o Hormos dentro do WSL...
REM  `wslpath "%CD%"` e NAO `wslpath "'%CD%'"`. Com as aspas simples por
REM  dentro, elas entravam no VALOR: o wslpath recebia o caminho ja entre
REM  aspas, nao convertia para /mnt/c/... e devolvia literalmente
REM  'C:/Users/.../hormos-main (1)/hormos-main'. A linha montada virava
REM  cp -r ''C:/...'/.' - aspas vazias, caminho SEM protecao e, quando a
REM  pasta tinha parenteses, erro de sintaxe no bash.
REM
REM  E a pasta TEM parenteses no caso mais comum: quem baixa o zip duas
REM  vezes recebe "hormos-main (1)" do proprio Windows. O caminho do
REM  usuario e o que tem espaco e parenteses, nao o do desenvolvedor.
set "SRC="
for /f "usebackq delims=" %%i in (`wsl -d %DISTRO% -u root -- wslpath "%CD%"`) do set "SRC=%%i"
if not defined SRC (
    echo  X Nao foi possivel converter o caminho desta pasta para o WSL.
    echo    Pasta: %CD%
    pause
    exit /b 1
)

REM  Sem `2^>/dev/null` e sem `; true` na copia: engolir o erro aqui fazia a
REM  falha aparecer tres comandos adiante, num "cd: No such file or
REM  directory" que nao diz a causa. Erro de copia tem de falar na hora.
wsl -d %DISTRO% -u root -- bash -c "mkdir -p /opt/hormos && cp -r '%SRC%/.' /opt/hormos/"
if %errorLevel% neq 0 (
    echo  X Falha ao copiar os arquivos para dentro do WSL.
    echo    Origem: %CD%
    echo    Confira se a pasta foi descompactada por completo.
    pause
    exit /b 1
)
wsl -d %DISTRO% -u root -- bash -c "cd /opt/hormos && chmod +x install.sh scripts/*.sh 2>/dev/null; true"
echo       Executando a instalacao (pode demorar na primeira vez)...
wsl -d %DISTRO% -u root -- bash -c "cd /opt/hormos && ./install.sh local"
if %errorLevel% neq 0 (
    echo  ✖ A instalacao dentro do WSL falhou. Veja as mensagens acima.
    pause
    exit /b 1
)

REM ── 7. Confiar na CA interna (Windows + Firefox) ──────────────────
echo  [7/7] Instalando o certificado da CA interna...
wsl -d %DISTRO% -u root -- bash -c "cd /opt/hormos && docker exec sgsi_caddy sh -c 'cat /data/caddy/pki/authorities/local/root.crt' > /opt/hormos/caddy/Hormos-CA-local.crt 2>/dev/null; true"
wsl -d %DISTRO% -u root -- bash -c "cp /opt/hormos/caddy/Hormos-CA-local.crt '%SRC%/caddy/Hormos-CA-local.crt' 2>/dev/null; true"
if exist "%CD%\caddy\Hormos-CA-local.crt" (
    certutil -addstore -f Root "%CD%\caddy\Hormos-CA-local.crt" >nul 2>&1
    if !errorLevel! equ 0 (
        echo  ✓ CA confiada no Windows ^(Chrome e Edge^).
    ) else (
        echo  ! Nao foi possivel instalar a CA automaticamente.
    )
    REM Firefox usa repositorio proprio: a politica abaixo faz ele
    REM confiar nas CAs do Windows, cobrindo todos os navegadores.
    for %%D in ("%ProgramFiles%\Mozilla Firefox" "%ProgramFiles(x86)%\Mozilla Firefox") do (
        if exist "%%~D" (
            if not exist "%%~D\distribution" mkdir "%%~D\distribution" >nul 2>&1
            > "%%~D\distribution\policies.json" echo {"policies":{"Certificates":{"ImportEnterpriseRoots":true}}}
            echo  ✓ Firefox configurado para usar as CAs do Windows.
        )
    )
) else (
    echo  ! CA nao localizada — o navegador podera exibir aviso de certificado.
)

echo.
REM ── O agendamento temporario nao sobrevive ao sucesso ────────────
REM  Ele ja saiu no inicio desta execucao, de proposito, para nao voltar a
REM  cada logon se a instalacao falhasse no meio. Apagar de novo aqui e
REM  barato e fecha a promessa feita a quem aceitou reiniciar: o agendamento
REM  sai quando o Hormos esta NO AR — e chegar nesta linha significa isso,
REM  porque o install.sh roda o conferir-saude.sh e o passo 5 aborta se ele
REM  falhar.
powershell -NoProfile -ExecutionPolicy Bypass -File "%RETOMA%" -Acao remover

echo  ═══════════════════════════════════════════════
echo    ✓ Hormos instalado
echo.
echo    Acesse:  https://localhost
echo.
echo    Feche o navegador POR COMPLETO antes de abrir,
echo    para que ele releia os certificados.
echo  ═══════════════════════════════════════════════
echo.

REM ── A credencial do Ubuntu ────────────────────────────────────────
REM  Mostrada aqui porque sem ela a pessoa nao abre o proprio terminal, e
REM  todo o bloco "como parar e ligar" logo abaixo manda abrir o Ubuntu.
set "SENHA_WSL="
for /f "usebackq delims=" %%P in (`wsl -d %DISTRO% -u root -- cat /root/.senha-ubuntu 2^>nul`) do set "SENHA_WSL=%%P"
if defined SENHA_WSL (
    echo  ───────────────────────────────────────────────────────────────
    echo   USUARIO E SENHA DO UBUNTU ^(ANOTE^)
    echo.
    echo     usuario:  %USUARIO_WSL%
    echo     senha:    !SENHA_WSL!
    echo.
    echo   Sao do Linux dentro do WSL, nao do Hormos. Servem para abrir o
    echo   aplicativo "Ubuntu" e rodar os comandos abaixo.
    echo.
    echo   Esqueceu? No PowerShell:
    echo     wsl -d %DISTRO% -u root cat /root/.senha-ubuntu
    echo  ───────────────────────────────────────────────────────────────
    echo.
)

REM ── Como operar depois ────────────────────────────────────────────
REM  Quem instala por aqui pode nunca ter usado Docker — e no Windows
REM  ainda há um degrau a mais: os comandos rodam DENTRO do WSL, não
REM  no PowerShell. Dizer isso aqui evita o chamado "colei o comando e
REM  deu erro", que seria o comando certo no lugar errado.
echo  ───────────────────────────────────────────────────────────────
echo   COMO PARAR E LIGAR O HORMOS
echo.
echo   Abra o aplicativo "Ubuntu" no menu Iniciar e rode:
echo.
echo     docker compose -p sgsi-appliance-core ps      ^| esta no ar?
echo     docker compose -p sgsi-appliance-core stop    ^| parar tudo
echo     docker compose -p sgsi-appliance-core start   ^| ligar
echo.
echo   Parar NAO apaga nada: os dados ficam guardados e o sistema
echo   volta como estava.
echo.
echo   DEPOIS DE REINICIAR O WINDOWS: o WSL nao roda sozinho em
echo   segundo plano. Se o https://localhost nao responder, abra o
echo   aplicativo "Ubuntu" uma vez e aguarde alguns segundos.
echo.
echo   Guia completo: https://hormosgrc.github.io/instalacao.html
echo  ───────────────────────────────────────────────────────────────
echo.
echo   SE A SENHA DO PRIMEIRO ACESSO SE PERDEU
echo.
REM  Aconteceu numa instalacao real: a janela fechou antes do primeiro
REM  login e a pessoa achou que precisaria reinstalar. A senha sempre
REM  esteve no .env, so que DENTRO do WSL — nao numa pasta do Explorador.
echo     Cole no PowerShell ^(nao no Ubuntu^):
echo.
echo       wsl -d %DISTRO% -u root grep MASTER_PASSWORD /opt/hormos/.env
echo.
echo   Ela vale para UM acesso. Depois do primeiro login a senha
echo   passa a ser a sua.
echo.
REM  NAO existe "Esqueci minha senha" na tela de login. Dizer que existia
REM  mandava a pessoa procurar um botao que nao esta la — o mesmo texto
REM  errado ja foi tirado do install.sh. Quem redefine e o script, dentro
REM  do Ubuntu.
echo   Perdeu a senha depois disso? No aplicativo "Ubuntu":
echo.
echo     cd /opt/hormos ^&^& sudo ./scripts/redefinir-senha-admin.sh
echo.
echo   ONDE RODAR CADA COMANDO
echo     - comeca com "wsl"            -^> PowerShell do Windows
echo     - comeca com "docker"         -^> aplicativo Ubuntu
REM  O relato de instalacao trouxe `wsl -d Ubuntu -u root` rodado DENTRO
REM  do Ubuntu, com "Command 'wsl' not found" — comando certo, ambiente
REM  errado. Esta regra de bolso resolve o caso que de fato apareceu.
echo.
start "" "https://localhost"
pause
endlocal
