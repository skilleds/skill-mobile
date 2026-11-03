---
name: schematize-mobile
metadata:
  version: 0.8.0
description: >-
  Mobile: nativo vs cross (fit + ADR), offline-first, IAM mobile (OIDC/PKCE, passkeys), push e lojas. Use ao revisar app iOS/Android/KMP/Flutter/RN, Info.plist ou AndroidManifest.
---
<!-- cross-skill: iam.md, linguagens.md -> schematize-engineering -->
<!-- cross-skill: protocolos.md -> schematize-iam -->

# Engenharia de apps mobile da casa (schematize-mobile)

Disciplina normativa para **apps mobile** — iOS, Android e cross-platform. A tese é uma só: o
**piso da casa não muda no mobile**. Segurança, IAM, testes, operação, Definition of Done (§35),
archive (§28), índice/MAPA (§39) são **os mesmos** de qualquer software da casa. O que o mobile
acrescenta é o **como**, sob duas verdades novas: o app **roda na máquina do adversário** (cliente
hostil) e **a rede falha o tempo todo** (offline por padrão). Esta skill especializa a
`schematize-engineering` (a base agnóstica) para esse recorte, sem afrouxar nenhum piso.

Um app não é uma ilha: é o **cliente** de uma arquitetura que já tem os pisos da casa — um backend
do **rol sancionado** (Go/Rust/Elixir/C#/Zig/Ruby) e um **IAM como app separada** em
`auth.<domain>` (o IdP da casa). O app **delega** authz e segredo ao servidor; ele é conveniência
de UX, nunca a fonte de verdade nem o guardião do segredo.

**Versão:** skill `schematize-mobile` v0.8.0. Changelog em `CHANGELOG.md`.

## Precedência e herança (leia antes de divergir)

<!-- herdado:engineering/precedencia:dominio intro="Esta skill é o recorte **mobile (iOS, Android, cross-platform)** da base: especializa a `schematize-engineering` para o cliente que roda na máquina do adversário e na rede que falha, sem afrouxar piso (`schematize-engineering` → `references/linguagens.md` §2.2)." cmd="mobile" -->Esta skill é o recorte **mobile (iOS, Android, cross-platform)** da base: especializa a `schematize-engineering` para o cliente que roda na máquina do adversário e na rede que falha, sem afrouxar piso (`schematize-engineering` → `references/linguagens.md` §2.2).

1. **Onde esta skill divergir da base, a BASE MANDA.** Aqui mora a especialização do domínio ou da
   ferramenta — o como, o padrão, o gate. Divergência de *piso* é defeito desta skill, não variante local.
2. **O que não está repetido aqui é HERDADO, não dispensado.** Esta skill herda os pisos da base e
   os comandos dela cobrem o **domínio**, não o piso geral. Valem integralmente, sem cópia local:
   - **§28 Archive** — `<projeto>/<projeto>_archive/` é **repositório git próprio, PRIVADO e
     obrigatório**, criticidade 0 (`schematize-archive`).
   - **§35 Definition of Done** e a lista de anti-padrões (citada por **título**, nunca por número).
   - **§39 Índice/MAPA** — enumeração exaustiva (uma entrada por unidade chamável, `M == N`) e grafo
     com arestas em ASCII (`A -> B`), nunca a seta unicode.
   - **IAM** (`schematize-engineering` → `references/iam.md`): identidade ≠ email, ≥2 fatores, ReBAC
     multi-tenant, argon2id-only para senha nova, sessão longa e logout irreversível.
   - **Efeito externo** nunca sai de não-produção (`schematize-engineering` →
     `references/efeitos-externos.md`).
   - **Orquestração** (`schematize-engineering` → `references/orquestracao.md` §9): o principal não
     desenvolve (é Claude Opus); executor mais barato que resolve — `haiku`/`sonnet` → Codex Terra → Cursor → `opus` só após falha; visual direto ao Codex; imagem nunca pelo Claude: detecta Codex/Gemini e pergunta ao usuário qual usar (Codex é a sugestão, não automática), nunca API paga.
3. **QA, ops, IAM e índice não têm comando próprio aqui:** vêm da base `/eng-*`. Para trabalho
   contínuo use `/eng-overdev`; para planejar `/eng-plan`; para varrer a base `/eng-scan`; para
   revisão geral `/eng-review` (e `/eng-ops`, `/eng-iam`, `/eng-index`). Os comandos
   `/mobile-*` cobrem o domínio desta skill; o piso geral é o da base.<!-- /herdado -->

## Comandos (Claude Code)

Digite `/mobile-help` pra ver todos. Em resumo:

| Comando | O que faz |
|---|---|
| `/mobile-help` | lista todos os comandos do schematize-mobile |
| `/mobile-load` | carrega à força TODO o corpo normativo (plataforma, offline/sync, IAM mobile, segurança, entrega, performance) e passa a aplicá-lo |
| `/mobile-auth` | força/audita o IAM mobile casado com o `iam.md`: OIDC/PKCE delegando ao `auth.<domain>`, passkeys+biometria, secure storage, logout irreversível, sem segredo no bundle |
| `/mobile-offline` | audita/planeja o offline-first & sync: UI lê do local, outbox durável, idempotência, delta sync, resolução de conflito explícita; roteiro de QA 100% offline |
| `/mobile-release` | prepara/audita o release de loja: assinatura em cofre, build assinado em tag/hml, staged/phased rollout com gate de crash-free + halt, OTA dentro das regras, review guidelines, kill-switch |
| `/mobile-test` | planeja/audita a **suíte de testes do app**: pirâmide no device, matriz de dispositivos datada, permissão negada, deep link, **migração do banco local**, processo morto, push |
| `/mobile-claude` | cria ou mescla o `CLAUDE.md` sempre-on de mobile na raiz do repo |
| `/mobile-cc` | context compact: gera handoff no archive e roda `/compact` |
| `/mobile-handoff` | gera o handoff (context.md + checklist.md) sem compactar |

Os comandos ficam em `assets/commands/` e são instalados em `.claude/commands/`.

## Como usar esta skill

1. **Decida a plataforma primeiro, com ADR** (`references/plataforma.md`): nativo (Swift/Kotlin)
   ou cross (KMP/Flutter/RN) por **fit + ADR (§27)**, como a política de linguagem da casa. A
   escolha é estrutural e vira registro, não gosto do dia.
   **Divisão de mando:** esta skill manda no que é de *app* (auth, offline/sync, push, lojas, performance); as de linguagem mandam no código — `schematize-swift` (iOS nativo), `schematize-kotlin` (Android/KMP) e `schematize-dart` (Flutter). Em conflito sobre auth/offline/push/loja, vale a mobile.
2. **Desenhe offline-first e sync** (`references/offline-sync.md`): a UI lê do local, a escrita é
   otimista com **outbox durável**, e a reconciliação (conflito/fila/idempotência) é um problema
   de dados distribuídos com política **explícita** — nenhuma escrita do usuário some em silêncio.
3. **IAM mobile casando com o `iam.md`** (`references/iam-mobile.md`): o app é **public client
   OIDC/PKCE** delegando ao `auth.<domain>`; passkeys+biometria no núcleo; tokens em
   Keychain/Keystore; **nunca** segredo no bundle; logout irreversível; authz no servidor.
4. **Segurança do cliente hostil** (`references/seguranca-mobile.md`): TLS+pinning, root/jailbreak
   e attestation como **sinal**, ofuscação sensata — defesa em profundidade, com a verdade sempre
   no servidor.
5. **Entrega e operação** (`references/entrega-lojas.md`): assinatura em cofre, build assinado só em tag/hml (piso 27),
   **staged/phased rollout** com gate de crash-free, OTA dentro das regras, observabilidade/crash.
6. **Performance/bateria/rede/push** (`references/performance.md`): medir, não adivinhar. No push,
   o que quebra em silêncio é o **token**: rotação, `POST_NOTIFICATIONS` (Android 13+) e limpeza do
   token morto.
7. **Teste como app, não como servidor** (`references/testes-mobile.md`): a pirâmide é da
   `schematize-qa`; aqui entram migração do banco local (não há rollback no device do usuário),
   permissão negada nos três estados, deep link com app fechado e usuário deslogado, processo morto
   pelo SO e a matriz de dispositivos **datada**.
8. **Não trabalhe de memória** — os pisos abaixo valem independentemente do reference carregado.

Mapa de references — leia o que casa com a tarefa:

| Tarefa | Reference |
|---|---|
| Escolher nativo vs cross por fit + ADR; arquitetura interna em camadas; app como cliente do backend/IdP da casa | `references/plataforma.md` |
| Offline-first, outbox de mutações, idempotência, delta sync, tombstones, resolução de conflito (LWW/merge/CRDT/servidor), testes de reconciliação | `references/offline-sync.md` |
| IAM mobile: OIDC/PKCE, deep link verificado, passkeys+biometria, secure storage, logout irreversível, authz no servidor — casado com o `iam.md` | `references/iam-mobile.md` |
| Segurança do cliente hostil: nunca segredo no bundle, cert/SPKI pinning, root/jailbreak+attestation, ofuscação, dado em repouso, deep link/IPC | `references/seguranca-mobile.md` |
| Entrega nas lojas: assinatura, build em tag/hml, staged/phased rollout+halt, OTA/regras de loja, review, observabilidade/crash | `references/entrega-lojas.md` |
| Performance, bateria, rede, tamanho e push notifications (ciclo de vida do token, `POST_NOTIFICATIONS`, limpeza de token morto); perfilar antes de otimizar | `references/performance.md` |
| **Testes no app**: o que muda no mobile — pirâmide com as fronteiras do device, matriz de dispositivos datada, permissão negada nos 3 estados, deep link, **migração do banco local**, processo morto pelo SO, rede ruim (não ausente), a11y no fontScale máximo | `references/testes-mobile.md` |
| Efeito externo fora de prd: build de não-prd que **não** fala com produção (build config/flavor), push em sandbox, conta de teste/review em domínio de rota nula, Email OTP contra o **sink** | `references/entrega-lojas.md` §7 + `references/iam-mobile.md` §8 (normativa: `schematize-engineering` → `references/efeitos-externos.md`) |

## Pisos inegociáveis (vetam o atalho)

Independente do reference, estes limites nunca são cruzados:

1. **O piso da casa é o MESMO — muda o "como".** Segurança, IAM, testes, ops, DoD (§35), archive
   (§28), índice (§39) valem inteiros. Mobile **não** é desculpa pra afrouxar nada; é o mesmo piso
   realizado num cliente hostil com rede ruim.
2. **NUNCA segredo no bundle.** API key privada, `client_secret`, chave de assinatura, credencial
   — nada no `.ipa`/`.apk`, código, plist/strings, `BuildConfig` ou var "pública". O app é **public
   client**; segredo que precisa existir fica no **servidor** atrás de um BFF. Extrair o bundle é
   trivial. (mesma regra do `NEXT_PUBLIC_` do `schematize-web`).
3. **Auth é delegada ao IdP da casa, no servidor.** O app **não** implementa login próprio: usa
   **OIDC/OAuth 2.1 + PKCE** contra `auth.<domain>`, retorno por **Universal/App Links verificados**
   e login no **navegador do sistema (não WebView)** (o desenho do broker é da `schematize-iam → references/protocolos.md`). Authz **sempre no servidor** (deny-default,
   token fino, ReBAC) — esconder botão é UX, não autorização.
4. **Secure storage para token/chave — e nada de vazamento.** Refresh e chaves em
   **Keychain/Keystore** (Secure Enclave/StrongBox); **nunca** em store em claro, e **nunca** token/
   PII em log, crash report ou analytics. Dado sensível e a outbox **cifrados em repouso**.
5. **Passkeys+biometria no núcleo — biometria não é autorização.** Passkeys de plataforma são o
   fator forte; **biometria desbloqueia local** a chave, **não** substitui **step-up server-side**
   pra operação sensível. Fallback via Email OTP always-on do IdP (`iam.md`). **Logout irreversível**
   (revoga refresh+família no IdP, desassocia push).
6. **Offline-first: a UI lê do local e nenhuma escrita some.** Escrita é otimista + **outbox
   durável** com **idempotência**; sync é **delta** com tombstones; **resolução de conflito é
   explícita** (ADR) e o **servidor é a fonte de verdade**. Descartar escrita do usuário em silêncio
   é vetado.
7. **Release com rollout gradual + gate — nunca 100% de uma vez.** Build **assinado pelo pipeline de tag/hml** (nunca por commit/PR; chaves
   em cofre), **staged/phased rollout** com gate de **crash-free/ANR** e **halt** na regressão;
   rollback é hotfix pra frente. OTA só de JS/config, **dentro das regras da loja**. Crash/ANR com
   símbolos e telemetria **sem PII**.
8. **O dispositivo é território hostil — defesa em profundidade, verdade no servidor.** TLS+**SPKI
   pinning** (com backup/rotação), root/jailbreak e **attestation** como **sinal** pro risk engine
   (não bloqueio ingênuo), **ofuscação sensata** que eleva custo mas **não** guarda segredo. Deep
   link/IPC são entrada hostil — valide. A decisão de segurança nunca migra pro cliente.
9. **Efeito externo NUNCA sai de não-produção — no mobile o build já está distribuído.** Normativa:
   piso 18 da `schematize-engineering` + `references/efeitos-externos.md` (rota nula, sink, guard no
   provider, cap por execução, chave sandbox). Recorte mobile: **(a)** build de dev/QA/TestFlight/
   internal/App Distribution **nunca** aponta pro backend nem provedor de prd — base URL,
   `client_id` e chaves por **build configuration/flavor/scheme**, **fail-closed** (config ausente =
   não-prd), **artefato assinado** inspecionado. **(b)** **Push em sandbox** (APNs `development` +
   FCM de teste); plist/`google-services.json` de prd em build de QA/TestFlight é VETADO. **(c)**
   Conta de teste/review/persona/fixture só em `test.<domain>` de rota nula ou TLD reservado; E2E
   de Email OTP lê o **sink**. Detalhe: `references/entrega-lojas.md` §7 e `references/iam-mobile.md` §8.
10. <!-- herdado:engineering/orquestracao:bullet -->**Orquestrador não desenvolve; subagent barato executa** (`schematize-engineering` → `references/orquestracao.md` §9). O principal só planeja/decompõe/despacha/supervisiona/revisa; ação onerosa vira micro-tasks; principal = Claude Opus; executor mais barato que resolve: `haiku` (mecânico) / `sonnet` (código, até 2 rodadas de correção pelo mesmo subagent) → Codex `gpt-5.6-terra` → Cursor → subagent `opus` (motivo no checkpoint) → `park`; **visual direto ao Codex; imagem nunca pelo Claude (pergunta ao usuário: Codex sugerido, ou Gemini), API de imagem paga PROIBIDA**; papéis configuráveis em `agentes.toml` (aba "Agentes" do overdev). No `overdev`, cada item do checklist é executado pelo papel adequado e revisado pelo principal (diff + gate) antes do `- [x]`. **Sem frota ociosa:** agent idle com pendência executável volta ao trabalho; pendência que depende de outro agent → mata e enfileira com gatilho de dependência; terminou → mata (§9.6).<!-- /herdado -->
<!-- herdado:engineering/pisos-22-29:bloco -->**Herda os pisos 22–29 da `schematize-engineering`** (texto completo em `assets/CLAUDE.md` dela): 22 tudo no git — sem remote, push falho ou HEAD≠origin a demanda NÃO se conclui; 23 deploy só do git (VETADO scp/rsync/tar|ssh/docker save|load/git bundle); 24 o ops é o gate da IA — a IA nunca muda a VPS direto nem escreve SQL, só operação nomeada (`ssh vps "ops <op>"`); 25 sem agents inúteis (entregou, morreu); 26 relatório a cada 30 min e handoff a cada 6 h; 27 CI remoto só antes do hml, a pedido ou em tag (`workflow_dispatch` + `hml-*`/`v*`; VETADO `pull_request`, `push` em branch, `workflow_run`, cron sem justificativa); 28 microserviço autônomo (fila durável + 7 testes de resiliência); 29 build/teste na máquina dev/hml quando existe (ponte só no workspace de build, nunca prd) + higiene (`scripts/higiene.sh`).<!-- /herdado -->

## Relação com as outras skills

- **schematize-engineering** — a **BASE** agnóstica. Esta skill herda e não afrouxa: **IAM**
  (`iam.md`, o modelo que o `iam-mobile.md` realiza), **DoD (§35)**, **archive (§28)**, **índice/
  MAPA (§39)**, **ops (§ ops.md)**, **cadeia de suprimentos**, **observabilidade**, e o fluxo
  (scan/plan/refactor/overdev/auditoria) — no laço do overdev cada item é executado por subagent `sonnet` e revisado pelo principal (`schematize-engineering` → `references/orquestracao.md` §9).
  **Anti-padrões (§37): esta skill NÃO tem lista própria — herda a da base por ponteiro**
  (`schematize-engineering` → `references/anti-padroes.md`), incluindo *"Disparar efeito externo
  REAL a partir de não-produção"*. É deliberado: a `schematize-mobile` segue o **modelo de
  ponteiro** (zero clone da base); o recorte mobile de cada anti-padrão que muda de forma no
  dispositivo está nos references desta skill, citado **pelo título** do item — nunca pelo número,
  porque a numeração do §37 diverge entre skills. A escolha de plataforma espelha a **política de linguagem**
  (`linguagens.md`): rol sancionado + fit + ADR.
- **schematize-go / rust / elixir / c# / zig / ruby** — o **backend** que o app consome. O app fala
  com um serviço do rol sancionado; a authz, a regra de negócio e o segredo moram lá.
- **schematize-web** — o **IdP/BFF web** e o fronte de auth compartilham o mesmo IAM; PWA/web app é
  frontend governado por ela (vira "app de loja" só com requisito nativo real). O piso "segredo
  nunca no cliente" é o mesmo dos dois lados.
- **schematize-pentest** — o **oráculo do cliente hostil**: BOLA/BFLA por confiar no que a tela
  mostrou, bypass de step-up/biometria, abuso de deep link, token em store inseguro, authz no
  cliente. O app vira superfície de ataque testável.
- **schematize-audit** — fecha o loop: os checklists de mobile (IAM/offline/release) viram itens
  provados, não marcados na fé.

- **schematize-qa** — a **disciplina de teste**, que esta skill herda inteira. O recorte mobile é
  o *onde roda* (emulador/simulador local por commit; device farm só em tag/hml ou a pedido, teste instrumentado vs unit na JVM/host,
  UI test que espera evento e não `sleep`, snapshot por densidade de tela) — mas a pirâmide, o
  "verde de verdade", o smoke com self-check, a política de **flaky** (endêmica em teste de UI:
  quarentena com prazo e dono, nunca `retry` infinito) e os **gates de CI** são da
  `schematize-qa`. Rollout escalonado com gate de crash-free é entrega, não substituto de teste —
  a `schematize-qa` é explícita em que gate não se desliga "por enquanto".
