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
echo  [1/7] Verificando o WSL...

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

REM ── O prompt do Canonical, antes que ele exista ───────────────────
REM  O Ubuntu recente pergunta, no primeiro uso interativo, se a pessoa quer
REM  enviar metricas para a Canonical — e FICA PARADO esperando resposta.
REM  Numa instalacao real foi o que sobrou: o Hormos subiu, mas o Ubuntu nao
REM  completava o provisionamento ate alguem abrir o terminal e responder.
REM
REM  A documentacao da Canonical da a saida: HKCU\Software\Canonical\Ubuntu,
REM  DWORD UbuntuInsightsConsent, 0 = nao participar, 1 = participar. O valor
REM  e lido SO na criacao da instancia, por isso vem aqui, antes do
REM  `wsl --install -d`.
REM
REM  Gravamos 0: nao e nossa decisao ligar telemetria para a Canonical em nome
REM  de quem instala. E NAO sobrescrevemos se a chave ja existir — essa
REM  resposta e da pessoa, nao do instalador.
reg query "HKCU\Software\Canonical\Ubuntu" /v UbuntuInsightsConsent >nul 2>&1
if %errorLevel% neq 0 (
    reg add "HKCU\Software\Canonical\Ubuntu" /v UbuntuInsightsConsent /t REG_DWORD /d 0 /f >nul 2>&1
    if !errorLevel! equ 0 (
        echo       Telemetria da Canonical: desativada ^(nao perguntara^).
    ) else (
        echo       ! Nao consegui pre-responder o aviso de metricas do Ubuntu.
        echo         Se ele aparecer ao abrir o Ubuntu, responda n e siga.
    )
)

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
    echo  [2/7] Distribuicao !ACHADA! ja instalada — nao vou baixar de novo.
) else (
    echo  [2/7] Instalando a distribuicao %DISTRO%...
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

REM ── 3. systemd (necessario para o servico do Docker subir sozinho) ─
echo  [3/7] Habilitando systemd no WSL...
wsl -d %DISTRO% -u root -- bash -c "grep -q '^systemd=true' /etc/wsl.conf 2>/dev/null || printf '[boot]\nsystemd=true\n' >> /etc/wsl.conf"
wsl --shutdown
timeout /t 3 /nobreak >nul

REM ── 4. Docker Engine + Compose DENTRO do WSL ──────────────────────
echo  [4/7] Verificando o Docker dentro do WSL...
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

REM  O grupo docker do usuario e tratado pelo preparar-usuario-wsl.sh, no
REM  passo 5 — que vem depois deste de proposito, porque e a instalacao do
REM  Docker que cria o grupo. Aqui esta linha expandiria %USUARIO_WSL% antes
REM  de ele existir, e rodaria `usermod -aG docker` sem usuario nenhum.


REM  'C:/Users/.../hormos-main (1)/hormos-main'. A linha montada virava
REM  cp -r ''C:/...'/.' - aspas vazias, caminho SEM protecao e, quando a
REM  pasta tinha parenteses, erro de sintaxe no bash.
REM
REM  E a pasta TEM parenteses no caso mais comum: quem baixa o zip duas
REM  vezes recebe "hormos-main (1)" do proprio Windows. O caminho do
REM  usuario e o que tem espaco e parenteses, nao o do desenvolvedor.
set "SRC="
for /f "usebackq delims=" %%i in (`wsl -d %DISTRO% -u root -- wslpath "%CD%"`) do set "SRC=%%i"

REM ── 5. O usuario do Linux ─────────────────────────────────────────
REM  POR QUE DEPOIS DO DOCKER: o usuario precisa entrar no grupo `docker`, e
REM  esse grupo so existe depois que o Docker e instalado. Antes este passo
REM  vinha em terceiro, com o grupo ainda inexistente.
REM
REM  POR QUE CHAMA UM SCRIPT, E NAO BASH INLINE: a versao anterior era um
REM  `wsl -- bash -c "..."` com pipe, redirecionamento, chaves e substituicao
REM  de comando dentro de aspas do cmd. A logica estava CERTA — testada
REM  isolada num Ubuntu real — mas a travessia pelo cmd entregou ao bash
REM  outra coisa: o arquivo da senha nunca foi criado, o chpasswd recebeu
REM  senha VAZIA e a tela mostrou "pam_chauthtok() failed". Tres camadas de
REM  aspas e o mesmo erro que eu ja havia evitado no PowerShell.
REM
REM  O script tem alternativa em CADA passo (chpasswd, depois passwd, depois
REM  hash + usermod; urandom, depois openssl, depois sha256), porque quem
REM  instala nao tem como consertar nada a mao. Os seis caminhos foram
REM  testados em Ubuntu 24.04 autenticando de verdade, nao so "sem erro".
echo  [5/7] Criando o usuario do Ubuntu...
set "USUARIO_WSL=hormos"
set "SENHA_WSL="

REM  A ULTIMA linha da saida e a senha; o relato vai para stderr, de proposito,
REM  para a captura aqui nao precisar de filtro nenhum.
for /f "usebackq delims=" %%P in (`wsl -d %DISTRO% -u root -- bash "%SRC%/scripts/preparar-usuario-wsl.sh" %USUARIO_WSL%`) do set "SENHA_WSL=%%P"

if not defined SENHA_WSL (
    echo.
    echo  X Nao foi possivel preparar o usuario %USUARIO_WSL% no %DISTRO%.
    echo    O motivo esta nas linhas acima.
    echo.
    echo    A instalacao do Hormos pode seguir sem ele, mas voce nao vai
    echo    conseguir abrir o aplicativo "Ubuntu" para operar o appliance.
    echo    Para criar um a mao depois, no PowerShell:
    echo      wsl -d %DISTRO% -u root
    echo      adduser seu_nome
    echo      usermod -aG sudo,docker seu_nome
    echo.
    set "RESP="
    set /p "RESP=  Continuar a instalacao mesmo assim? [S/n]: "
    if /i "!RESP!"=="n" (
        pause
        exit /b 1
    )
) else (
    echo  ✓ Usuario %USUARIO_WSL% pronto ^(a senha aparece no fim^).
)

REM ── 6. Copia o projeto para dentro do WSL e instala ───────────────
echo  [6/7] Preparando o Hormos dentro do WSL...
REM  `wslpath "%CD%"` e NAO `wslpath "'%CD%'"`. Com as aspas simples por
REM  dentro, elas entravam no VALOR: o wslpath recebia o caminho ja entre
REM  aspas, nao convertia para /mnt/c/... e devolvia literalmente
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

REM ── As credenciais, num arquivo em Documentos ─────────────────────
REM  POR QUE EM ARQUIVO E NAO SO NA TELA: mostrar e dizer "anote" falha com
REM  usuario leigo. Um Enter distraido fecha a janela, e a pessoa perde o
REM  acesso ao proprio terminal sem saber o comando para recuperar.
REM  Documentos porque e onde ela vai dar de cara com o arquivo depois.

REM  As credenciais do Hormos saem do .env. Lidas com `tokens=1,* delims==`
REM  para partir no primeiro "=" — sem pipe, sem aspas simples e sem `^^` no
REM  meio, que e o tipo de linha que o cmd entrega ao bash diferente do que
REM  esta escrita. Ja custou uma instalacao hoje.
set "HORMOS_USUARIO="
set "HORMOS_SENHA="
for /f "usebackq tokens=1,* delims==" %%A in (`wsl -d %DISTRO% -u root -- grep -m1 MASTER_EMAIL /opt/hormos/.env`) do set "HORMOS_USUARIO=%%B"
for /f "usebackq tokens=1,* delims==" %%A in (`wsl -d %DISTRO% -u root -- grep -m1 MASTER_PASSWORD /opt/hormos/.env`) do set "HORMOS_SENHA=%%B"

REM ── A credencial do Ubuntu ────────────────────────────────────────
REM  Mostrada aqui porque sem ela a pessoa nao abre o proprio terminal, e
REM  todo o bloco "como parar e ligar" logo abaixo manda abrir o Ubuntu.
REM  NAO zera o SENHA_WSL aqui: ele ja veio do passo 5, que e a fonte
REM  autoritativa. Zerar e reler jogava fora o valor que temos em maos, e se
REM  a releitura falhasse a credencial nao apareceria mesmo estando conhecida.
REM  A releitura e so para o caso de o passo 5 ter sido pulado.
if not defined SENHA_WSL (
    for /f "usebackq delims=" %%P in (`wsl -d %DISTRO% -u root -- cat /root/.senha-ubuntu 2^>nul`) do set "SENHA_WSL=%%P"
)
REM  Grava o arquivo ANTES de imprimir qualquer coisa, para a mensagem da
REM  tela poder dizer onde ele esta — ou dizer que nao deu, em vez de
REM  prometer um arquivo que nao existe.
set "ARQ_CRED="
if defined SENHA_WSL (
    for /f "usebackq delims=" %%F in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\gravar-credenciais.ps1" -UsuarioWsl "!USUARIO_WSL!" -SenhaWsl "!SENHA_WSL!" -UsuarioHormos "!HORMOS_USUARIO!" -SenhaHormos "!HORMOS_SENHA!" -Distro "!DISTRO!"`) do set "ARQ_CRED=%%F"
)

if defined SENHA_WSL (
    echo  ───────────────────────────────────────────────────────────────
    echo   SUAS SENHAS
    echo.
    echo   Ubuntu / WSL ^(o sistema^)
    echo     usuario:  !USUARIO_WSL!
    echo     senha:    !SENHA_WSL!
    echo.
    if defined HORMOS_SENHA (
        echo   Hormos ^(o portal, em https://localhost^)
        echo     usuario:  !HORMOS_USUARIO!
        echo     senha:    !HORMOS_SENHA!     ^(vale para UM acesso^)
        echo.
    )
    if defined ARQ_CRED (
        echo  ═══════════════════════════════════════════════════════════════
        echo   NAO PRECISA ANOTAR. Esta tudo neste arquivo:
        echo.
        echo     !ARQ_CRED!
        echo.
        echo   Ele esta na sua pasta Documentos. Guarde as senhas no seu
        echo   gerenciador e depois APAGUE o arquivo — ele tem senha em
        echo   texto aberto, e quem abrir este computador le.
        echo  ═══════════════════════════════════════════════════════════════
    ) else (
        echo   ! Nao consegui gravar o arquivo em Documentos. ANOTE as senhas
        echo     acima antes de fechar esta janela. Para ver de novo depois:
        echo       wsl -d !DISTRO! -u root cat /root/.senha-ubuntu
        echo       wsl -d !DISTRO! -u root grep MASTER_PASSWORD /opt/hormos/.env
    )
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
