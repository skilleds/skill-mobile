#!/usr/bin/env bash
# check-mobile-effects.test.sh — vermelho visto: o furo era caixa real em fastlane/.maestro/yaml/
# xcconfig/plist passar batido (o gate herdado só varria test/seed/fixture). Entrada: nenhuma.
# Saída: exit 0 se todos os casos passam.
# EXCEÇÃO DECLARADA de strict mode: harness sem `-e` para reportar todos os casos.
set -uo pipefail
G="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/check-mobile-effects.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
rc=0
caso() { # nome, esperado, args...
  local nome="$1" esp="$2"; shift 2
  OUT=$(bash "$G" "$@" 2>&1); z=$?
  if [ "$z" -eq "$esp" ]; then echo "  ✔ $nome (exit $z)"; else echo "  ✖ $nome: exit $z: $OUT"; rc=1; fi
}
P="$W/limpo"; mkdir -p "$P/fastlane" "$P/.maestro"
printf 'username: qa+1@test.exemplo.test\n' > "$P/.maestro/login.yaml"
printf 'apple_id("qa@test.exemplo.test")\n' > "$P/fastlane/Appfile"
printf '<key>aps-environment</key>\n<string>development</string>\n' > "$P/App.entitlements"
caso "projeto limpo passa" 0 --nonprd "$P"
for f in ".maestro/login.yaml" "fastlane/Appfile" "Config/Dev.xcconfig" "Info.plist" "ci/app.yml"; do
  P="$W/real-$(echo "$f" | tr '/.' '__')"; mkdir -p "$P/$(dirname "$f")"
  printf 'user=fulano@gmail.com\n' > "$P/$f"
  caso "caixa real em $f bloqueia" 1 "$P"
done
P="$W/apns"; mkdir -p "$P"
printf '<key>aps-environment</key>\n<string>production</string>\n' > "$P/App.entitlements"
caso "aps production com --nonprd bloqueia" 1 --nonprd "$P"
caso "aps production sem --nonprd passa" 0 "$P"
[ $rc -eq 0 ] && echo "✔ check-mobile-effects.test.sh: todos os casos" || echo "✖ falhou"
exit $rc
