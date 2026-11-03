---
description: schematize-mobile — prepara/audita o release de loja (assinatura em cofre, build em tag/hml, staged/phased rollout com gate + halt, OTA nas regras, review, kill-switch, crash com símbolos)
argument-hint: "[track alvo, ex: internal | testflight | production]"
---
<!-- cross-skill: observabilidade.md -> schematize-engineering -->

Prepare/audite o **release de loja** deste app (`references/entrega-lojas.md`). Entre o commit e o
usuário há uma **loja** (revisão, assinatura, rollout gradual) e o binário na mão do usuário **não
tem rollback instantâneo** — por isso rollout gradual e observabilidade são inegociáveis.

## 1. Assinatura e credenciais (segredo de ops)
- Chaves de assinatura (**upload/app signing key Android**, certificados/perfis iOS) em **cofre** —
  nunca no repo/laptop. **Play App Signing** / assinatura gerenciada Apple quando possível.
- **Build de release assinado pelo pipeline** (não na máquina de alguém), disparado só por tag `hml-*`/`v*`, `workflow_dispatch` ou pedido do usuário (piso 27; nunca por commit/PR), rastreável ao commit (archive §28). Device farm/matriz: idem.

## 2. Versão e trilhos
- **SemVer** (marketing) + **build number monotônico** (nunca reusado). Passe por trilho de teste
  (`internal → TestFlight/closed → open beta → production`) antes de produção.

## 3. Staged/phased rollout — nunca 100% de uma vez
- Configure **staged rollout (Play)** / **phased release (iOS)** com **gate de crash-free/ANR** vs.
  a versão anterior; **halt** na regressão. Rollback = **hotfix pra frente** (o gradual contém o
  dano em % pequeno).

## 4. OTA e kill-switch
- **Kill-switch/feature flags** da feature nova (liga/desliga sem review).
- OTA só de **JS bundle/config**, **dentro das regras** (Apple 2.5.2 / Google — não muda propósito
  aprovado nem burla review), **assinado** e **compatível** com a faixa de versão nativa. Código
  nativo/permissão/SDK novo → **passa pela loja**.

## 5. Review guidelines
- Verifique as regras **antes**: Sign in with Apple quando há social; **sem** pagamento de bem
  digital fora do IAP; permissão **just-in-time** com purpose string honesta; **App Privacy / Data
  safety / ATT** corretos. Forneça **conta/roteiro de teste** ao revisor.

## 6. Observabilidade/crash
- **Crash + ANR** com stack simbolicada (**dSYM/mapping/ProGuard map** subidos); crash-free como
  métrica de gate. **Telemetria sem PII/segredo** (scrub de token/email). Métricas de cold start/
  sync/funil (casa com `observabilidade.md`).

## 7. Efeito externo — build de teste NUNCA fala com produção
Normativa: piso 18 da `schematize-engineering`. Recorte: base URL/`client_id`/chaves por build
configuration/flavor, **fail-closed**, artefato assinado inspecionado; push em sandbox; conta de
teste só em `test.<domain>` de rota nula; Email OTP lê o **sink**. Detalhe: `entrega-lojas.md` §7.

## Saída
Rode a **DoD de release mobile** (`entrega-lojas.md` §8) e reporte cada item como **FEITO com prova**
ou **EM ABERTO**. Faltando assinatura em cofre, gate de rollout, símbolos de crash, OTA fora das
regras, **build de não-prd apontando pra produção** ou conta de teste em caixa real → **não fecha** (dívida rastreável, não "sobe e reza").
