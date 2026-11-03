<!-- cross-skill: iam.md -> schematize-engineering -->
# CLAUDE.md — Engenharia de Apps Mobile da Casa (sempre on)

> Copie para a **raiz do repositório** do app e ajuste `<project>`. Fica pinado no contexto de
> toda tarefa e garante o piso mesmo quando a skill `schematize-mobile` não dispara sozinha. Em
> repo multi-skill (ex.: monorepo com backend), use **junto** com os `CLAUDE.md` das skills de
> engenharia e da linguagem do backend (rode `/mobile-claude` que mescla, sem sobrescrever os
> outros blocos).

## Regra mestre

App mobile é software da casa como qualquer outro: **o piso — segurança, IAM, testes, ops, DoD
(§35), archive (§28), índice (§39) — é o MESMO**. O mobile só muda o **como**, sob duas verdades:
o dispositivo é **cliente hostil** e a rede é **offline por padrão**. Em conflito entre "é só um
app, relaxa" e este piso, **o piso vence**. Consulte o reference antes de agir — não trabalhe de
memória.

## Pisos inegociáveis (VETADO — sem exceção)

1. **O piso da casa é o MESMO — muda o "como".** Segurança, IAM, testes, ops, DoD (§35), archive
   (§28), índice (§39) valem inteiros; mobile não é desculpa pra afrouxar.
2. **NUNCA segredo no bundle.** API key privada, `client_secret`, chave de assinatura, credencial
   — nada no `.ipa`/`.apk`, código, plist/`strings.xml`, `BuildConfig` ou var "pública". O app é
   **public client**; segredo que precisa existir fica no **servidor** atrás de um BFF. Achou
   segredo no rastro → **rotação** + remoção.
3. **Auth delegada ao IdP da casa, no servidor.** O app **não** implementa login: **OIDC/OAuth 2.1
   + PKCE** contra `auth.<domain>`, retorno por **Universal/App Links verificados**, login no
   **navegador do sistema (não WebView)**. **Authz sempre no servidor** (deny-default, token fino,
   ReBAC) — esconder botão é UX, não autorização. Desenho do broker: `schematize-iam`.
4. **Secure storage e zero vazamento.** Refresh/chaves em **Keychain/Keystore** (Secure Enclave/
   StrongBox); **nunca** em store em claro; **nunca** token/PII em log, crash report ou analytics.
   Dado sensível e a outbox de sync **cifrados em repouso**.
5. **Passkeys+biometria no núcleo — biometria ≠ autorização.** Passkeys de plataforma são o fator
   forte; **biometria desbloqueia local** a chave, **não** substitui **step-up server-side** pra
   op sensível. Fallback via Email OTP always-on do IdP. **Logout irreversível** (revoga refresh+
   família no IdP, desassocia push).
6. **Offline-first sem perder escrita.** A UI **lê do local**; escrita é otimista + **outbox
   durável** com **idempotência**; sync é **delta** com tombstones; **conflito é resolvido por
   política explícita** (ADR) e o **servidor é a fonte de verdade**. Descartar escrita do usuário
   em silêncio é vetado.
7. **Release com rollout gradual + gate.** Build **assinado pelo pipeline de tag/hml** (nunca por commit/PR; chaves em cofre),
   **staged/phased rollout** com gate de **crash-free/ANR** e **halt** na regressão (rollback é
   hotfix pra frente). OTA só de JS/config, **dentro das regras da loja**. Crash/ANR com símbolos,
   telemetria **sem PII**.
8. **Device é território hostil — defesa em profundidade, verdade no servidor.** TLS + **SPKI
   pinning** (com backup/rotação); root/jailbreak e **attestation** como **sinal** pro risk engine
   (não bloqueio ingênuo); **ofuscação sensata** eleva custo mas **não** guarda segredo; deep link/
   IPC são entrada hostil (valide). A decisão de segurança nunca migra pro cliente.
9. **Efeito externo NUNCA sai de não-produção — no mobile o build já está distribuído.** Normativa:
   piso 18 da `schematize-engineering` + `references/efeitos-externos.md` (rota nula, sink, guard no
   provider, cap por execução, chave sandbox). Recorte mobile: **(a)** build de dev/QA/TestFlight/
   internal/App Distribution **nunca** aponta pro backend nem provedor de prd — base URL,
   `client_id` e chaves por **build configuration/flavor/scheme**, **fail-closed** (config ausente =
   não-prd), **artefato assinado** inspecionado. **(b)** **Push em sandbox** (APNs `development` +
   FCM de teste); plist/`google-services.json` de prd em build de QA/TestFlight é VETADO. **(c)**
   Conta de teste/review/persona/fixture só em `test.<domain>` de rota nula ou TLD reservado; E2E
   de Email OTP lê o **sink**. Detalhe: `references/entrega-lojas.md` §7 e `references/iam-mobile.md` §8.
10. <!-- herdado:engineering/orquestracao:longo -->**Orquestrador não desenvolve; subagent barato executa.** O agent principal (o que fala com o humano, Claude Opus) **só planeja, decompõe, despacha, supervisiona e revisa** — não escreve código de entrega. Toda ação onerosa é quebrada em **micro-tasks/micro-funções** executáveis por agent barato (mesmo com <3 unidades: em série, por subagents, nunca inline no principal). Principal = **Claude Opus** (só orquestra). Roteamento: mecânico/muito simples → **`haiku`**; código → **`sonnet`** (falhou → o **mesmo subagent corrige**, até 2 rodadas) → **Codex `gpt-5.6-terra`** → **Cursor** (`cursor-agent`, se instalado) → **subagent `opus`** (motivo no checkpoint) → `park` + `- [~]`; escala **só quando o mais barato falhar**. **Visual (UI/layout/CSS/tema/ícone) vai direto ao Codex** (Claude é fraco em visual); **imagem nunca pelo Claude: detectar Codex/Gemini e PERGUNTAR ao usuário qual usar (Codex, cota da assinatura, é a sugestão — não automático) — PROIBIDO endpoint/API de imagem pago.** Estrutura configurável em `agentes.toml` (global `~/.claude/schematize/agentes.toml` + override por projeto) e na aba "Agentes" do overdev; Codex/Cursor via `schematize overdev delegar --papel <p> --brief-stdin --json` (rc 3 = indisponível → `proximo`). O principal revisa toda entrega (diff + gate) e **só corrige com a própria mão se necessário** (trivial, 1–2 linhas). No overdev, **cada item do checklist é executado pelo agente do papel adequado (default subagent `sonnet`)** e revisado pelo principal antes do `- [x]`; escalar não é pergunta, esgotou a escada → `park`. **Sem frota ociosa:** agent idle com pendência executável volta ao trabalho; pendência que depende de outro agent → mata e enfileira com gatilho de dependência; terminou → mata (§9.6). Detalhe em `schematize-engineering` → `references/orquestracao.md` §9.<!-- /herdado -->
<!-- herdado:engineering/pisos-22-29:bloco -->**Herda os pisos 22–29 da `schematize-engineering`** (texto completo em `assets/CLAUDE.md` dela): 22 tudo no git — sem remote, push falho ou HEAD≠origin a demanda NÃO se conclui; 23 deploy só do git (VETADO scp/rsync/tar|ssh/docker save|load/git bundle); 24 o ops é o gate da IA — a IA nunca muda a VPS direto nem escreve SQL, só operação nomeada (`ssh vps "ops <op>"`); 25 sem agents inúteis (entregou, morreu); 26 relatório a cada 30 min e handoff a cada 6 h; 27 CI remoto só antes do hml, a pedido ou em tag (`workflow_dispatch` + `hml-*`/`v*`; VETADO `pull_request`, `push` em branch, `workflow_run`, cron sem justificativa); 28 microserviço autônomo (fila durável + 7 testes de resiliência); 29 build/teste na máquina dev/hml quando existe (ponte só no workspace de build, nunca prd) + higiene (`scripts/higiene.sh`).<!-- /herdado -->

## Definition of Done

Nada é "pronto" sem: unit + UI/instrumentado verdes, fluxo crítico com e2e, **nenhum efeito externo
real fora de produção** (build de dev/QA/TestFlight nunca aponta pro backend nem pro provedor de
`prd`; push em sandbox APNs / projeto FCM de teste; conta de teste/review em domínio de **rota
nula**; Email OTP lido do **sink** — gate em `scripts/check-external-effects.sh`), crash-free acima
do gate de rollout, sem segredo no bundle, **índice atualizado**, **archive commitado**, gate local verde (CI remoto só em tag/hml) e
review aprovado. A DoD (§35) é a da base, `schematize-engineering` → `references/entrega.md`; o
recorte mobile está em `references/entrega-lojas.md`.

## Como se decide aqui

- **Plataforma (`/mobile-load`, `plataforma.md`):** nativo (Swift/Kotlin) vs cross (KMP/Flutter/RN)
  por **fit + ADR (§27)** — como a política de linguagem da casa. Registre o porquê.
- **IAM mobile (`/mobile-auth`, `iam-mobile.md`):** casa com o `iam.md`; audita OIDC/PKCE, deep
  link verificado, passkeys+biometria, secure storage, logout irreversível, authz no servidor.
- **Offline/sync (`/mobile-offline`, `offline-sync.md`):** outbox, idempotência, delta sync,
  conflito explícito; roteiro de QA 100% offline.
- **Release (`/mobile-release`, `entrega-lojas.md`):** assinatura, build em tag/hml, staged rollout+gate,
  OTA nas regras, review, crash com símbolos, **build de não-prd que não fala com produção** (§7).

## Relação com as outras skills

- **schematize-engineering** — a base: IAM (`iam.md`), DoD (§35), archive (§28), índice (§39).
- **backend do rol** (go/rust/elixir/csharp/zig/ruby) — o serviço que o app consome (authz/regra/
  segredo moram lá).
- **schematize-web** — mesmo IdP/IAM; "segredo nunca no cliente" dos dois lados.
- **schematize-pentest** — o app é superfície de ataque (BOLA/BFLA, bypass de step-up, deep link).

## Gestão de contexto (sessões longas)

Ao se aproximar do teto de contexto: **PARE e** gere o handoff em `<project>_archive/context/`
(estado + FEITO vs EM ABERTO) **antes** de compactar (`/mobile-cc`).
