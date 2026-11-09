<#
  estado-wsl.ps1 — responde, por codigo de saida, as duas perguntas que o
  install.bat nao consegue responder sozinho sem errar.

  Por que existe um .ps1 em vez de PowerShell embutido no .bat:

    1. Embutido, ele viraria uma linha `for /f %%S in ('powershell -Command
       ^"...^"')` com tres niveis de escape de aspas — cmd, depois PowerShell,
       depois a string. E o tipo de linha que ninguem revisa e que quebra
       silenciosamente, devolvendo vazio em vez de erro. Aqui o codigo e
       legivel e da para testar.

    2. `dism /online /get-featureinfo` nao serve: a saida dele e TRADUZIDA.
       Num Windows pt-BR vem "Estado : Habilitado", e qualquer comparacao com
       "Enabled" falha. O Get-WindowsOptionalFeature devolve um ENUM, cujo
       nome nao muda de idioma — e esta maquina e pt-BR.

  Saidas de `-Checar plataforma`:
     0  ATIVO      — o WSL funciona agora
     1  REINICIAR  — instalado, porem so vale depois do proximo boot
     2  AUSENTE    — nao esta instalado

  Saidas de `-Checar distro`:
     0  registrada — e imprime o NOME real dela na saida padrao
     1  nao registrada
#>
param(
    [ValidateSet('plataforma','distro')] [string] $Checar = 'plataforma',
    [string] $Nome = 'Ubuntu'
)

$ErrorActionPreference = 'SilentlyContinue'

function Estado-Do-Recurso($nome) {
    # Gancho de TESTE, e so de teste: a tabela de decisao abaixo e o coracao
    # deste conserto, e sem poder forcar "EnablePending" nao havia como provar
    # que ela decide certo — so afirmar. Fora de um teste a variavel nao
    # existe, e esta linha nao muda nada no Windows de ninguem.
    if ($env:HORMOS_TESTE_RECURSOS) {
        foreach ($par in $env:HORMOS_TESTE_RECURSOS -split ';') {
            $kv = $par -split '=', 2
            if ($kv[0] -eq $nome) { return [string]$kv[1] }
        }
        return ''
    }
    try { return [string](Get-WindowsOptionalFeature -Online -FeatureName $nome).State }
    catch { return '' }
}

function Distros-Registradas {
    # `wsl -l -q` nao tem UMA codificacao: o wsl.exe antigo sai em UTF-16LE,
    # e o 2.x respeita a pagina de codigo do console — e o install.bat faz
    # `chcp 65001`, ou seja, pode vir UTF-8. Nao da para escolher uma e
    # confiar.
    #
    # Tentei forcar [Console]::OutputEncoding = Unicode e TESTEI: isso
    # conserta o UTF-16 e DESTROI o UTF-8. "Ubuntu" virava "払湵畴" — a
    # distro existia, a comparacao falhava, e o instalador baixaria de novo.
    # Era o mesmo defeito com outra roupa.
    #
    # O que funciona nos dois casos e nao mexer na codificacao e tirar os
    # NUL: se vier UTF-16 lido como byte a byte, "U\0b\0u\0..." volta a ser
    # "Ubuntu"; se vier UTF-8, nao ha NUL nenhum e a limpeza nao faz nada.
    $cru = & wsl.exe -l -q 2>$null

    return @($cru) |
        ForEach-Object { ($_ -replace "`0", '' -replace '\uFEFF', '').Trim() } |
        Where-Object { $_ -ne '' }
}

if ($Checar -eq 'plataforma') {

    $vmp = Estado-Do-Recurso 'VirtualMachinePlatform'
    $wsl = Estado-Do-Recurso 'Microsoft-Windows-Subsystem-Linux'

    # PENDENTE decide antes de tudo. "EnablePending" significa que alguem
    # acabou de habilitar e falta o boot — e exatamente o estado em que a
    # instalacao real seguiu em frente e deu permissao negada em todo o resto.
    if ($vmp -like '*Pending*' -or $wsl -like '*Pending*') { exit 1 }

    # Depois, o comportamento vale mais que a introspeccao: se o wsl.exe
    # responde, o WSL esta ativo — inclusive no Windows 11 novo, onde ele vem
    # da Store e o recurso opcional Microsoft-Windows-Subsystem-Linux pode
    # aparecer desabilitado numa maquina perfeitamente funcional. Decidir pelo
    # recurso aqui mandaria reinstalar o WSL de quem ja o tem.
    & wsl.exe --version *> $null
    if ($LASTEXITCODE -eq 0) { exit 0 }
    & wsl.exe --status  *> $null
    if ($LASTEXITCODE -eq 0) { exit 0 }

    # O wsl.exe nao respondeu. So agora o recurso serve de desempate: a
    # plataforma de virtualizacao e o que o WSL2 realmente exige.
    if ($vmp -eq 'Enabled') { exit 0 }

    exit 2
}

# -Checar distro: imprime o nome REAL da distro encontrada.
# Aceitar o prefixo importa: quem ja tem "Ubuntu-24.04" tem Ubuntu. Exigir o
# nome exato mandaria baixar uma segunda distribuicao Ubuntu ao lado da que
# ja esta instalada — o desperdicio que este instalador existe para evitar.
$lista = Distros-Registradas

$exata = $lista | Where-Object { $_ -ieq $Nome } | Select-Object -First 1
if ($exata) { Write-Output $exata; exit 0 }

$prefixo = $lista | Where-Object { $_ -ilike "$Nome*" } | Select-Object -First 1
if ($prefixo) { Write-Output $prefixo; exit 0 }

exit 1
