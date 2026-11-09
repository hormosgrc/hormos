#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════
# Hormos — testes do caminho de instalação do WINDOWS.
#
# POR QUE EXISTE: numa instalação real, depois que o `wsl --install`
# terminou de instalar o Ubuntu, TODO o resto do script falhou com
# "permissão negada" — mesmo rodando como administrador. A causa era
# reinício pendente do Windows: os recursos ficam em "EnablePending" e
# só passam a valer no próximo boot. A detecção de então (`where wsl` +
# `wsl --status`) dava os dois casos como iguais e seguia em frente.
#
# O QUE ESTE TESTE PODE E NÃO PODE FAZER: não existe Windows aqui, então
# ele não prova que a instalação funciona. Prova outra coisa, que é onde
# os defeitos realmente moravam:
#
#   · a ESTRUTURA do .bat — final de linha, parênteses, rótulos, e o
#     `pause ^& exit` que anuncia a falha e segue em frente;
#   · a TABELA DE DECISÃO do estado-wsl.ps1, forçando "EnablePending"
#     por variável de ambiente. É o coração do conserto, e sem isso só
#     daria para afirmar que decide certo;
#   · a leitura de `wsl -l -q` nas DUAS codificações que ele usa.
#
# O que fica sem prova está dito no fim, em voz alta. Checagem que falha
# para o lado do "pode seguir" é pior que não ter checagem.
#
# Uso: ./scripts/testar-instalador-windows.sh
# ════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$(dirname "$0")/.."

FALHAS=0
SEM_PROVA=0
ok()    { echo "  ✓ $1"; }
falha() { echo "  ✖ $1"; FALHAS=$((FALHAS+1)); }
checar(){ if [ "$2" = "$3" ]; then ok "$1"; else falha "$1 — obtive [$2], esperava [$3]"; fi; }

BAT=install.bat
PS_ESTADO=scripts/estado-wsl.ps1
PS_RETOMA=scripts/retomar-instalacao.ps1

echo "═══ A · estrutura do install.bat ═══"

# O cmd.exe exige CR+LF. Com LF puro os `goto`, rótulos e blocos entre
# parênteses se comportam de forma errática — o sintoma relatado foi a
# janela abrir e fechar na hora. E quem baixa o ZIP recebe os bytes COMO
# ESTÃO no repositório, sem a conversão que o `git clone` faria.
lf_solto=$(python3 -c "d=open('$BAT','rb').read(); print(d.count(b'\n')-d.count(b'\r\n'))")
checar "todas as linhas terminam em CRLF" "$lf_solto" "0"

# \r\r\n passa pela checagem acima: a diferença entre \n e \r\n é zero nos
# dois casos. Já aconteceu — uma gravação com newline='\r\n' sobre um texto
# que já tinha CRLF dobrou o CR em todas as 406 linhas, e a suíte ficou verde.
# Tem de procurar a sequência, não contar.
crcrlf=$(python3 -c "print(open('$BAT','rb').read().count(b'\r\r\n'))")
checar "nenhum CR duplicado (\\r\\r\\n)" "$crcrlf" "0"

# `pause ^& exit /b 1` dentro de um bloco ( ... ): o caret torna o & LITERAL,
# o pause recebe "& exit /b 1" como argumento e ignora, e o exit NUNCA roda.
# O instalador imprime "falha" e continua instalando sobre o erro.
if grep -qE 'pause \^?& exit' "$BAT"; then
  falha "há 'pause & exit' na mesma linha — o exit pode não rodar dentro de um bloco"
else
  ok "nenhum pause/exit colado na mesma linha"
fi

python3 - "$BAT" <<'PY'
import io,re,sys
L=io.open(sys.argv[1],encoding='utf-8',newline='').readlines()
prof=0; sobra=[]
for i,l in enumerate(L,1):
    t=l.strip()
    if t.startswith('REM') or t.startswith('::'): continue
    if re.match(r'^\)\s*else\s*\($',t): continue
    if t==')':
        prof-=1
        if prof<0: sobra.append(i); prof=0
    elif t.endswith('('): prof+=1
print('  %s parênteses de bloco balanceados%s' % (
      ('✓','') if prof==0 and not sobra else ('✖',' — resto %d, sobrando nas linhas %s'%(prof,sobra))))
rot={re.match(r'^:(\w+)',l.strip()).group(1) for l in L if re.match(r'^:\w+',l.strip())}
g={m.group(1) for l in L for m in [re.search(r'goto :(\w+)',l)] if m and not l.strip().startswith('REM')}
print('  %s todo goto tem rótulo%s' % (('✓','') if not g-rot else ('✖',' — sem destino: %s'%(g-rot))))
dup=[r for r in rot if sum(1 for l in L if l.strip()==':'+r)>1]
print('  %s nenhum rótulo duplicado%s' % (('✓','') if not dup else ('✖',' — %s'%dup)))
sys.exit(0 if prof==0 and not sobra and not (g-rot) and not dup else 1)
PY
[ $? -eq 0 ] || FALHAS=$((FALHAS+1))

echo
echo "═══ B · o .bat não volta a confiar no que o enganou ═══"

# `where wsl` não prova nada: o wsl.exe acompanha o Windows mesmo sem o WSL
# instalado. Era essa a detecção, e é por isso que o instalador seguia em
# frente numa máquina que ainda não podia rodar nada.
if grep -qE '^\s*where wsl' "$BAT"; then
  falha "voltou a decidir por 'where wsl'"
else
  ok "não decide mais por 'where wsl'"
fi

for f in "$PS_ESTADO" "$PS_RETOMA"; do
  base=$(basename "$f")
  grep -qF "$base" "$BAT" || falha "o .bat não chama o $base"
  [ -f "$f" ]              || falha "$f não existe"
  # O PowerShell 5.1 — que é o powershell.exe que o Windows traz — lê .ps1
  # SEM BOM como ANSI, e todo acento dos comentários vira lixo.
  [ "$(head -c3 "$f" | xxd -p)" = "efbbbf" ] && ok "$base tem BOM de UTF-8" \
    || falha "$base está sem BOM — o PowerShell 5.1 vai ler como ANSI"
  s=$(python3 -c "d=open('$f','rb').read(); print(d.count(b'\n')-d.count(b'\r\n'))")
  checar "$base todo em CRLF" "$s" "0"
  # Construções que só existem no PowerShell 6/7. O Windows traz o 5.1, e
  # `\`u{...}` ali é erro de SINTAXE: o script não roda, nem um pouco.
  if grep -qE '`u\{|\?\?|\$PSStyle' "$f"; then
    falha "$base usa sintaxe que não existe no PowerShell 5.1"
  else
    ok "$base é compatível com o PowerShell 5.1"
  fi
done

# O ZIP entrega os bytes do repositório. Sem a regra no .gitattributes, o
# próximo commit feito num Mac devolveria tudo para LF.
for padrao in '*.bat' '*.ps1'; do
  if grep -qF "$padrao text eol=crlf" .gitattributes; then
    ok "o .gitattributes fixa CRLF para $padrao"
  else
    falha "o .gitattributes não fixa CRLF para $padrao — o ZIP sairá errado"
  fi
done

echo
if ! command -v pwsh >/dev/null 2>&1; then
  echo "═══ C e D · NÃO VERIFICADOS: não há PowerShell nesta máquina ═══"
  echo "  A tabela de decisão e a leitura de 'wsl -l -q' ficaram sem prova."
  echo "  Instale o PowerShell (brew install powershell) para rodá-las."
  SEM_PROVA=2
else
  STUB="$(mktemp -d)"
  trap 'rm -rf "$STUB"' EXIT
  # Um wsl.exe de mentira: devolve a lista na codificação pedida e finge
  # responder (ou não) ao --version/--status.
  cat > "$STUB/wsl.exe" <<'STUBEOF'
#!/bin/sh
case "$1" in
  --version|--status) [ "$FAKE_WSL_FUNCIONA" = "1" ] && exit 0; exit 1 ;;
  -l) python3 -c 'import os,sys; sys.stdout.buffer.write(
        os.environ.get("FAKE_DISTROS","").encode(os.environ.get("FAKE_ENC","utf-16-le")))'; exit 0 ;;
esac
exit 1
STUBEOF
  chmod +x "$STUB/wsl.exe"
  export PATH="$STUB:$PATH"

  echo "═══ B2 · nenhuma variável local sobrescreve um parâmetro ═══"
  # ISTO QUEBROU UMA INSTALAÇÃO REAL. `$acao = New-ScheduledTaskAction ...`
  # sobrescrevia o PARÂMETRO `$Acao`, porque no PowerShell nome de variável
  # não diferencia maiúscula de minúscula. O ValidateSet do parâmetro roda na
  # atribuição e rejeitava: "o valor MSFT_TaskExecAction não é válido para a
  # variável Acao".
  #
  # E a suíte tinha passado: aqui o cmdlet não existe, então estourava ANTES
  # da atribuição e o teste nunca tocou a linha com o defeito. Esta checagem é
  # estática de propósito — não depende de rodar no Windows.
  col=$(pwsh -NoProfile -Command '
    $saida = @()
    foreach ($f in "'"$PS_ESTADO"'","'"$PS_RETOMA"'") {
      $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $f), [ref]$null, [ref]$null)
      $par = @($ast.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
      $atr = @($ast.FindAll({ $args[0] -is [System.Management.Automation.Language.AssignmentStatementAst] }, $true) |
               ForEach-Object { $_.Left } |
               Where-Object { $_ -is [System.Management.Automation.Language.VariableExpressionAst] } |
               ForEach-Object { $_.VariablePath.UserPath }) | Sort-Object -Unique
      foreach ($a in $atr) { if ($par | Where-Object { $_ -ieq $a }) { $saida += "$f atribui a `$$a" } }
    }
    $saida -join "; "')
  if [ -z "$col" ]; then ok "nenhum parâmetro é sobrescrito por variável local"
  else falha "parâmetro sobrescrito — $col"; fi

  echo
  echo "═══ C · tabela de decisão da plataforma ═══"
  E=VirtualMachinePlatform; W=Microsoft-Windows-Subsystem-Linux
  caso() { # caso <descrição> <recursos> <wsl.exe responde> <código esperado>
    HORMOS_TESTE_RECURSOS="$2" FAKE_WSL_FUNCIONA="$3" \
      pwsh -NoProfile -File "$PS_ESTADO" -Checar plataforma >/dev/null 2>&1
    checar "$1" "$?" "$4"
  }
  caso "tudo habilitado e wsl responde → ATIVO"        "$E=Enabled;$W=Enabled"       1 0
  caso "VMP EnablePending → REINICIAR"                 "$E=EnablePending;$W=Enabled" 0 1
  caso "WSL EnablePending → REINICIAR"                 "$E=Enabled;$W=EnablePending" 0 1
  # O caso que quebrou em campo: o wsl.exe JÁ responde, mas o recurso está
  # pendente. Se o comportamento vencesse aqui, o instalador seguiria em
  # frente e tudo adiante daria permissão negada. Pendente tem de vencer.
  caso "pendente E wsl.exe respondendo → REINICIAR"    "$E=EnablePending;$W=Enabled" 1 1
  caso "nada instalado → AUSENTE"                      "$E=Disabled;$W=Disabled"     0 2
  # Win11 novo: o WSL vem da Store e o recurso opcional pode aparecer
  # desabilitado numa máquina perfeitamente funcional. Decidir pelo recurso
  # aqui mandaria reinstalar o WSL de quem já o tem.
  caso "Store: recurso off mas wsl responde → ATIVO"   "$E=Disabled;$W=Disabled"     1 0
  caso "VMP on e wsl.exe calado → ATIVO"               "$E=Enabled;$W=Disabled"      0 0

  echo
  echo "═══ D · leitura de 'wsl -l -q' nas duas codificações ═══"
  # O wsl.exe antigo sai em UTF-16LE; o 2.x respeita a página de código do
  # console, e o install.bat faz `chcp 65001` — ou seja, pode vir UTF-8.
  # Forçar uma das duas conserta um caso e destrói o outro.
  distro() { # distro <descrição> <lista> <codificação> <código> <nome>
    out=$(FAKE_DISTROS="$2" FAKE_ENC="$3" pwsh -NoProfile -File "$PS_ESTADO" \
          -Checar distro -Nome Ubuntu 2>/dev/null); cod=$?
    nome=$(printf '%s' "$out" | tr -d '\n\r')
    if [ "$cod" = "$4" ] && [ "$nome" = "$5" ]; then ok "$1 ($3)"
    else falha "$1 ($3) — código $cod nome [$nome], esperava $4 [$5]"; fi
  }
  for enc in utf-16-le utf-8; do
    distro "Ubuntu exata"  "Ubuntu
docker-desktop" "$enc" 0 Ubuntu
    # Quem já tem "Ubuntu-24.04" TEM Ubuntu. Exigir o nome exato mandaria
    # baixar uma segunda distribuição ao lado da que já está instalada —
    # exatamente o desperdício que este conserto existe para evitar.
    distro "Ubuntu-24.04 pelo prefixo" 'Ubuntu-24.04' "$enc" 0 Ubuntu-24.04
    distro "sem Ubuntu nenhum"         'Debian'       "$enc" 1 ''
    distro "lista vazia"               ''             "$enc" 1 ''
  done

  echo
  echo "═══ E · contrato do retomar-instalacao.ps1 ═══"
  # Remover é obrigação, não cortesia: se a tarefa sobreviver a uma
  # instalação que falhou, ela volta a CADA logon, para sempre.
  pwsh -NoProfile -File "$PS_RETOMA" -Acao remover  >/dev/null 2>&1
  checar "remover é idempotente (sem tarefa → 0)"  "$?" "0"
  pwsh -NoProfile -File "$PS_RETOMA" -Acao consumir >/dev/null 2>&1
  checar "consumir não falha sem tarefa (→ 0)"     "$?" "0"
  pwsh -NoProfile -File "$PS_RETOMA" -Acao agendar -Script /nao/existe.bat >/dev/null 2>&1
  checar "agendar recusa caminho inexistente (→ 2)" "$?" "2"

  # O caminho mais comum do usuário é o pior caso: quem baixa o ZIP duas
  # vezes recebe "hormos-main (1)" do próprio Windows, com espaço E
  # parênteses. É por isso que a tarefa é criada por Register-ScheduledTask
  # e não por `schtasks /tr "\"%~f0\""`.
  D="$(mktemp -d)/hormos-main (1)/hormos-main"; mkdir -p "$D"; : > "$D/install.bat"
  erro=$(pwsh -NoProfile -File "$PS_RETOMA" -Acao agendar -Script "$D/install.bat" 2>&1 >/dev/null)
  if printf '%s' "$erro" | grep -qF "Caminho do instalador nao encontrado"; then
    falha "caminho com espaço e parênteses foi rejeitado pela validação"
  else
    ok "caminho com espaço e parênteses passa inteiro pela validação"
  fi
fi

echo
if [ "$FALHAS" -eq 0 ]; then
  echo "✓ caminho do Windows aprovado em tudo o que dá para verificar aqui"
  [ "$SEM_PROVA" -gt 0 ] && echo "  (atenção: $SEM_PROVA grupos de testes não rodaram — leia acima)"
  echo
  echo "  O que NENHUM teste aqui prova: que a instalação no Windows funciona."
  echo "  O reinício, o agendamento e a retomada só se provam num Windows real."
else
  echo "✖ $FALHAS verificação(ões) falharam"
  exit 1
fi
