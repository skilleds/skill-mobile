---
description: schematize-mobile — lista todos os comandos disponíveis e o que cada um faz
---
<!-- cross-skill: iam.md -> schematize-engineering -->

Liste os comandos do **schematize-mobile** instalados (`/mobile-*`), com 1 linha cada:

- `/mobile-help` — esta lista.
- `/mobile-test` — planeja/audita a **suíte de testes do app** (pirâmide no device, matriz de dispositivos datada, permissão negada nos 3 estados, deep link, migração do banco local, processo morto pelo SO, push contra servidor falso). A base é a `schematize-qa`.
- `/mobile-load` — carrega à força TODO o corpo normativo (plataforma, offline/sync, IAM mobile, segurança, entrega nas lojas, performance) e passa a aplicá-lo.
- `/mobile-auth` — força/audita o **IAM mobile** casado com o `iam.md`: public client **OIDC/PKCE** delegando ao `auth.<domain>`, deep link verificado (não WebView), **passkeys+biometria** (biometria desbloqueia local, não autoriza), **secure storage** (Keychain/Keystore), **logout irreversível**, authz no servidor, **sem segredo no bundle**.
- `/mobile-offline` — audita/planeja o **offline-first & sync**: UI lê do local, **outbox** durável, idempotência, delta sync, tombstones, **resolução de conflito explícita**; gera roteiro de QA 100% offline.
- `/mobile-release` — prepara/audita o **release de loja**: assinatura em cofre, build assinado no pipeline de tag/hml, **staged/phased rollout** com gate de crash-free/ANR e **halt**, OTA de JS/config **nas regras** da loja, review guidelines, kill-switch, crash com símbolos e telemetria sem PII.
- `/mobile-claude` — cria ou mescla o `CLAUDE.md` sempre-on de mobile na raiz do repo.
- `/mobile-cc` — context compact: gera handoff no archive e roda `/compact`.
- `/mobile-handoff` — gera o handoff (context.md + checklist.md) sem compactar.

Depois da lista, lembre a **regra de ouro**: *o piso da casa é o MESMO — o mobile só muda o
"como".* O dispositivo é **cliente hostil** e a rede é **offline por padrão**: por isso segredo
**nunca** no bundle, auth **delegada ao IdP** com authz no servidor, tokens em secure storage,
offline-first que **não perde escrita**, e release com **rollout gradual + gate**. Detalhe
normativo em `references/` da skill `schematize-mobile`; a base (IAM/DoD/archive/índice) é a
`schematize-engineering`.
