<#
  retomar-instalacao.ps1 — agenda (ou remove) a continuacao do install.bat
  depois do reinicio que o Windows exige para ativar o WSL.

  Por que nao e um `schtasks` direto no .bat:

    O caminho do instalador precisa ir entre aspas para o schtasks, e a linha
    viraria  /tr "\"%~f0\"" . Mas o cmd NAO processa \" como escape: ele
    entrega a barra invertida literal, e o que o Agendador guarda como comando
    depende de regra de parsing que eu nao consigo verificar sem um Windows na
    mao. E o caminho mais comum do usuario e justamente o pior caso — quem
    baixa o zip duas vezes recebe "hormos-main (1)" do proprio Windows, com
    espaco E parenteses.

    Register-ScheduledTask recebe o caminho como STRING de parametro. Nao ha
    shell no meio, nao ha aspas para acertar, e espaco e parentese deixam de
    ser um problema em vez de serem um problema resolvido por sorte.

  -Acao agendar   exige -Script com o caminho completo do install.bat
  -Acao remover   nao exige nada; nao reclama se a tarefa nao existir
  -Acao consumir  remove E informa se existia: saida 10 = existia (estamos
                  retomando apos o reinicio), 0 = nao existia (execucao normal).
                  Remover no COMECO, e nao so no fim, e o que garante uma
                  tentativa por agendamento: se a instalacao falhar depois do
                  reinicio, a tarefa nao fica voltando a cada logon para sempre.

  Saida 0 = feito. Qualquer outra = o .bat cai no caminho manual, que pede o
  reinicio a mao. Falhar em agendar nunca pode impedir a instalacao.
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('agendar','remover','consumir')] [string] $Acao,
    [string] $Script,
    [string] $Nome = 'HormosRetomarInstalacao'
)

$ErrorActionPreference = 'Stop'

function Remover-Tarefa {
    try { Unregister-ScheduledTask -TaskName $Nome -Confirm:$false -ErrorAction SilentlyContinue } catch { }
}

try {
    if ($Acao -eq 'remover') { Remover-Tarefa; exit 0 }

    if ($Acao -eq 'consumir') {
        # A pergunta vai em try PROPRIO, e a remocao acontece de qualquer
        # jeito. Se o Get-ScheduledTask falhar e levar o bloco inteiro com
        # ele, a tarefa fica no lugar e volta a cada logon para sempre — o
        # exato problema que esta acao existe para impedir. Saber se existia e
        # so para a mensagem na tela; remover e a obrigacao.
        $existia = $false
        try { $existia = $null -ne (Get-ScheduledTask -TaskName $Nome -ErrorAction SilentlyContinue) } catch { }
        Remover-Tarefa
        if ($existia) { exit 10 }
        exit 0
    }

    if (-not $Script -or -not (Test-Path -LiteralPath $Script)) {
        [Console]::Error.WriteLine("Caminho do instalador nao encontrado: $Script")
        exit 2
    }
    $completo = (Resolve-Path -LiteralPath $Script).Path

    # Idempotente: reagendar nao pode empilhar duas tarefas.
    Remover-Tarefa

    # ONLOGON e nao ONSTART: a instalacao conversa com o WSL, que e por
    # usuario, nao um servico de maquina. RunLevel Highest volta ja elevado,
    # para nao parar num UAC com a pessoa longe do teclado.
    $acao     = New-ScheduledTaskAction -Execute $completo -WorkingDirectory (Split-Path -LiteralPath $completo)
    $gatilho  = New-ScheduledTaskTrigger -AtLogOn
    $conta    = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) `
                                           -LogonType Interactive -RunLevel Highest
    # ExecutionTimeLimit zero = sem limite: a instalacao baixa imagens e pode
    # passar do teto padrao de 72h em rede ruim, e ser morta no meio seria
    # pior que demorar.
    $config   = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
                                             -ExecutionTimeLimit ([TimeSpan]::Zero) -StartWhenAvailable

    Register-ScheduledTask -TaskName $Nome -Action $acao -Trigger $gatilho `
                           -Principal $conta -Settings $config -Force | Out-Null
    exit 0
}
catch {
    # Write-Error aqui, com $ErrorActionPreference='Stop', lancaria outro erro
    # terminante e a mensagem se perderia — e ela e a unica pista que a pessoa
    # tem de por que a retomada automatica nao foi agendada.
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
