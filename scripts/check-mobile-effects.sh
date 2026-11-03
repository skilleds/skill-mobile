#!/usr/bin/env bash
# check-mobile-effects.sh — gate LOCAL (por commit) do recorte mobile do piso de efeito externo.
# Complementa o `check-external-effects.sh` herdado (que não se edita aqui: o sync-herdados o
# sobrescreve) cobrindo o que `entrega-lojas.md` §7.3 promete: caixa REAL em fastlane/, .maestro/,
# *.yaml/*.yml, *.xcconfig, *.plist e *.entitlements. Com --nonprd, também barra
# `aps-environment` = production nesses arquivos (build de dev/QA nunca usa APNs de produção).
# Uso: bash scripts/check-mobile-effects.sh [--nonprd] [dir]      Sai 1 se achar violação.
# EXCEÇÃO DECLARADA de strict mode: coletor (varre tudo e soma achados), logo sem `-e`.
set -uo pipefail
NONPRD=0
if [[ "${1:-}" == "--nonprd" ]]; then NONPRD=1; shift; fi
DIR="${1:-.}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAIL=0
REAIS='gmail\.com|googlemail\.com|hotmail\.com|outlook\.com|live\.com|msn\.com|yahoo\.com(\.br)?|icloud\.com|me\.com|proton(mail)?\.(me|com|ch)|aol\.com|uol\.com\.br|bol\.com\.br|terra\.com\.br|globo\.com|zoho\.com|yandex\.(ru|com)|gmx\.(com|net|de)|mail\.ru|qq\.com|163\.com'
echo "== check-mobile-effects (dir: $DIR) =="
[[ -f "$HERE/check-external-effects.sh" ]] && { bash "$HERE/check-external-effects.sh" "$DIR" || FAIL=1; }

mapfile -t ALVOS < <(find "$DIR" -type f \
  \( -path '*/fastlane/*' -o -path '*/.maestro/*' -o -name '*.yaml' -o -name '*.yml' \
     -o -name '*.xcconfig' -o -name '*.plist' -o -name '*.entitlements' \) \
  -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/Pods/*' \
  -not -path '*/build/*' -not -path '*/DerivedData/*' -not -path '*/.github/*' 2>/dev/null || true)

if (( ${#ALVOS[@]} > 0 )); then
  HITS=$(grep -nEI "[[:alnum:]._%+-]+@($REAIS)" "${ALVOS[@]}" 2>/dev/null || true)
  if [[ -n "$HITS" ]]; then
    echo "✗ BLOQUEIA caixa REAL em fastlane/Maestro/yaml/xcconfig/plist:"
    echo "$HITS" | sed 's/^/    /' | head -40
    echo "    → use <papel>+<run-id>-<n>@test.<domain> (rota nula) ou TLD reservado — entrega-lojas.md §7.3"
    FAIL=1
  fi
  if (( NONPRD )); then
    APNS=$(grep -nEIA1 'aps-environment' "${ALVOS[@]}" 2>/dev/null | grep -iE 'production' || true)
    if [[ -n "$APNS" ]]; then
      echo "✗ BLOQUEIA aps-environment=production em build não-prd:"
      echo "$APNS" | sed 's/^/    /' | head -20
      FAIL=1
    fi
  fi
fi
if (( FAIL )); then echo "== FALHOU: efeito externo mobile pode escapar de não-produção. =="; exit 1; fi
echo "== OK: nenhum efeito externo real detectado nos artefatos mobile. =="
