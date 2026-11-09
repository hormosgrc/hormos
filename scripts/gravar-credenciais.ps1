<#
  gravar-credenciais.ps1 — grava as credenciais num arquivo de texto na pasta
  Documentos da pessoa, e devolve o caminho completo.

  POR QUE EXISTE: a versao anterior mostrava usuario e senha na TELA e dizia
  "anote". Se a pessoa der Enter sem ler, a janela fecha e ela perde o acesso
  ao proprio terminal — e nao sabe o comando para recuperar. "Anotar da tela"
  nao e instrucao para usuario leigo, e isso aconteceu numa instalacao real.

  Documentos, e nao a Area de Trabalho nem a pasta da instalacao: e onde a
  pessoa vai dar de cara com o arquivo depois, procurando qualquer coisa.

  O caminho e perguntado ao Windows com GetFolderPath('MyDocuments'), nao
  montado como "$env:USERPROFILE\Documents": quem tem o OneDrive ativo tem a
  pasta REDIRECIONADA, e o caminho montado a mao aponta para um lugar que a
  pessoa nao abre — ou que nao existe.

  Saida: o caminho completo do arquivo na saida padrao. Codigo 0 = gravou.
#>
param(
    [Parameter(Mandatory=$true)] [string] $UsuarioWsl,
    [Parameter(Mandatory=$true)] [string] $SenhaWsl,
    [string] $UsuarioHormos = '',
    [string] $SenhaHormos   = '',
    [string] $Distro        = 'Ubuntu',
    [string] $Endereco      = 'https://localhost'
)

$ErrorActionPreference = 'Stop'

function Pasta-Destino {
    foreach ($nome in 'MyDocuments','Desktop','UserProfile') {
        try {
            $p = [Environment]::GetFolderPath($nome)
            if ($p -and (Test-Path -LiteralPath $p)) { return $p }
        } catch { }
    }
    # Ultimo recurso: a pasta pessoal pela variavel de ambiente.
    if ($env:USERPROFILE -and (Test-Path -LiteralPath $env:USERPROFILE)) { return $env:USERPROFILE }
    return $null
}

try {
    $pasta = Pasta-Destino
    if (-not $pasta) { [Console]::Error.WriteLine('Nao encontrei a pasta Documentos.'); exit 1 }

    $arquivo = Join-Path $pasta 'Hormos - usuario e senha.txt'
    $hoje    = Get-Date -Format 'dd/MM/yyyy HH:mm'

    $linhas = New-Object System.Collections.Generic.List[string]
    $linhas.Add('===============================================================')
    $linhas.Add(' HORMOS - INSTALACAO NO WINDOWS')
    $linhas.Add(" Gerado automaticamente pelo instalador em $hoje")
    $linhas.Add('===============================================================')
    $linhas.Add('')
    $linhas.Add('Este arquivo tem DUAS senhas diferentes. Elas nao se misturam.')
    $linhas.Add('')
    $linhas.Add('---------------------------------------------------------------')
    $linhas.Add(' 1) UBUNTU / WSL  -  o sistema onde o Hormos roda')
    $linhas.Add('---------------------------------------------------------------')
    $linhas.Add('')
    $linhas.Add("   usuario:  $UsuarioWsl")
    $linhas.Add("   senha:    $SenhaWsl")
    $linhas.Add('')
    $linhas.Add('   Para que serve: abrir o aplicativo "Ubuntu" no menu Iniciar')
    $linhas.Add('   e rodar os comandos de parar e ligar o Hormos. E a senha que')
    $linhas.Add('   o "sudo" pede.')
    $linhas.Add('')
    $linhas.Add('   Se perder: abra o PowerShell e rode')
    $linhas.Add("     wsl -d $Distro -u root cat /root/.senha-ubuntu")
    $linhas.Add('')
    if ($UsuarioHormos -or $SenhaHormos) {
        $linhas.Add('---------------------------------------------------------------')
        $linhas.Add(' 2) HORMOS  -  o portal, no navegador')
        $linhas.Add('---------------------------------------------------------------')
        $linhas.Add('')
        $linhas.Add("   endereco: $Endereco")
        if ($UsuarioHormos) { $linhas.Add("   usuario:  $UsuarioHormos") }
        if ($SenhaHormos)   { $linhas.Add("   senha:    $SenhaHormos") }
        $linhas.Add('')
        $linhas.Add('   ATENCAO: esta senha vale para UM unico acesso. No primeiro')
        $linhas.Add('   login o Hormos pede para voce criar a sua. A que voce criar')
        $linhas.Add('   NAO fica em arquivo nenhum - guarde-a voce mesmo.')
        $linhas.Add('')
        $linhas.Add('   Se perder a senha de uso unico ANTES do primeiro login:')
        $linhas.Add("     wsl -d $Distro -u root grep MASTER_PASSWORD /opt/hormos/.env")
        $linhas.Add('')
        $linhas.Add('   Se perder a SUA senha DEPOIS do primeiro login, no Ubuntu:')
        $linhas.Add('     cd /opt/hormos && sudo ./scripts/redefinir-senha-admin.sh')
        $linhas.Add('')
    }
    $linhas.Add('---------------------------------------------------------------')
    $linhas.Add(' COMO PARAR E LIGAR O HORMOS')
    $linhas.Add('---------------------------------------------------------------')
    $linhas.Add('')
    $linhas.Add('   Abra o aplicativo "Ubuntu" no menu Iniciar e rode:')
    $linhas.Add('')
    $linhas.Add('     docker compose -p sgsi-appliance-core ps      (esta no ar?)')
    $linhas.Add('     docker compose -p sgsi-appliance-core stop    (parar tudo)')
    $linhas.Add('     docker compose -p sgsi-appliance-core start   (ligar)')
    $linhas.Add('')
    $linhas.Add('   Parar NAO apaga nada. Os dados ficam guardados e o sistema')
    $linhas.Add('   volta como estava.')
    $linhas.Add('')
    $linhas.Add('   Guia completo: https://hormosgrc.github.io/instalacao.html')
    $linhas.Add('')
    $linhas.Add('---------------------------------------------------------------')
    $linhas.Add(' SEGURANCA')
    $linhas.Add('---------------------------------------------------------------')
    $linhas.Add('')
    $linhas.Add('   Este arquivo tem senhas em texto aberto. Ele existe para voce')
    $linhas.Add('   nao perder o acesso, nao para morar aqui: depois de guardar as')
    $linhas.Add('   senhas no seu gerenciador, APAGUE este arquivo. Quem abrir')
    $linhas.Add('   este computador le o que esta aqui.')
    $linhas.Add('')
    $linhas.Add('===============================================================')

    # UTF8 sem BOM nao existe no Set-Content do PowerShell 5.1, e o Bloco de
    # Notas antigo mostra "Ã§" onde deveria haver "ç". Entao o texto e todo sem
    # acento, de proposito, e gravado em ASCII puro: abre igual em qualquer
    # Windows, em qualquer editor, sem depender de codificacao.
    Set-Content -LiteralPath $arquivo -Value $linhas -Encoding ASCII

    if (-not (Test-Path -LiteralPath $arquivo)) {
        [Console]::Error.WriteLine("Gravei sem erro mas o arquivo nao esta la: $arquivo")
        exit 1
    }
    Write-Output $arquivo
    exit 0
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
