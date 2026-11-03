---
description: schematize-mobile — carrega à força TODO o corpo normativo (plataforma, offline/sync, IAM mobile, segurança, entrega, performance) e passa a aplicá-lo
---
<!-- cross-skill: iam.md -> schematize-engineering -->

Carregue **à força** e passe a aplicar **integralmente** os Padrões de Engenharia de Apps Mobile
da Casa (skill `schematize-mobile`) neste projeto. A partir de agora, nesta sessão, isto **não é
opcional**.

1. **Leia agora, na íntegra, TODOS os references** — não trabalhe de memória. Caminho:
   `.claude/skills/schematize-mobile/references/*.md` (projeto) ou
   `~/.claude/skills/schematize-mobile/references/*.md` (global):
   - `plataforma.md` — rol de plataformas sancionadas (nativo Swift/Kotlin, cross KMP/Flutter/RN),
     escolha por **fit + ADR (§27)** (espelha a política de linguagem), arquitetura interna em
     camadas, app como cliente do backend/IdP da casa.
   - `offline-sync.md` — offline-first (UI lê do local), **outbox** durável de mutações,
     idempotência, delta sync, tombstones, **resolução de conflito explícita** (LWW/merge/CRDT/
     servidor-autoritativo), UX de estado de rede, testes de reconciliação.
   - `iam-mobile.md` — o IAM mobile **casado com o `iam.md`**: public client **OIDC/PKCE** ao
     `auth.<domain>`, deep link verificado (não WebView), **passkeys+biometria**, secure storage
     (Keychain/Keystore), **logout irreversível**, authz no servidor.
   - `testes-mobile.md` — o que o **dispositivo** muda no teste: fronteiras da pirâmide no app
     (a base é a `schematize-qa`), **matriz de dispositivos datada**, permissão negada nos três
     estados, deep link com app fechado/deslogado, **migração do banco local** (sem rollback no
     device do usuário), processo morto pelo SO, rede ruim (não ausente), a11y no fontScale máximo.
   - `seguranca-mobile.md` — cliente hostil: **nunca segredo no bundle**, TLS+SPKI pinning,
     root/jailbreak+attestation como **sinal**, ofuscação sensata, dado cifrado em repouso, deep
     link/IPC como entrada hostil.
   - `entrega-lojas.md` — assinatura em cofre, build assinado só em tag/hml (piso 27), **staged/phased rollout** com gate +
     **halt**, OTA nas regras, review guidelines, observabilidade/crash sem PII, e §7: **build de
     não-prd NUNCA fala com produção** (ambiente por build config/flavor, push em sandbox, conta de
     teste em domínio de rota nula).
   - `performance.md` — cold start/main thread, bateria (WorkManager/BGTaskScheduler), rede (delta/
     coalescing/cache), **push** (APNs/FCM, token atado à sessão), tamanho, perfilar antes de otimizar.

2. **Confirme ao usuário** que leu (1 linha por arquivo).

3. Deste ponto, aplique como regra inegociável: **o piso da casa é o mesmo** (segurança/IAM/testes/
   ops/DoD §35/archive §28/índice §39), **nunca segredo no bundle**, **auth delegada ao IdP** com
   authz no servidor, **secure storage** sem vazamento, **passkeys+biometria** no núcleo (biometria
   não autoriza), **logout irreversível**, **offline-first sem perder escrita**, **release com
   rollout gradual + gate**, **device é território hostil** (defesa em profundidade, verdade no
   servidor), **efeito externo NUNCA fora de produção** (build de dev/QA/TestFlight não aponta pra
   prd, push em sandbox, conta de teste em rota nula, Email OTP lido no sink).

4. **Atualize o `CLAUDE.md` da raiz** com `assets/CLAUDE.md` da skill (mescla se já houver de
   outra skill) — é o `/mobile-claude`.
