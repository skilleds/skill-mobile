# Changelog — schematize-mobile

Todas as mudanças relevantes deste pacote, no formato [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
com versionamento [SemVer](https://semver.org/lang/pt-BR/).


## [Não lançado]

### Corrigido
- Gatilho de CI (piso 27): `entrega-lojas.md` ganha §1.1; build assinado, matriz e device farm só em tag `hml-*`/`v*`, `workflow_dispatch` ou pedido do usuário, nunca por commit/PR; o gate por commit é local. Textos "assinado no CI"/"CI verde"/"Todo PR" ajustados em SKILL.md, assets/CLAUDE.md, comandos e `testes-mobile.md`.
- `entrega-lojas.md` §4: frase truncada sobre OTA de JS refeita; citação de OTA trocada de "Apple 3.3.1" para **2.5.2**, conferida no texto oficial (https://developer.apple.com/app-store/review/guidelines/, 2026-11-03).
- Tabela de gates voláteis (target API, 16 KB, privacy manifest) removida de `entrega-lojas.md` §4.1; fica só em `stack-versoes.md` (números inalterados).
- Piso de efeito externo deduplicado em SKILL.md, `assets/CLAUDE.md` e `/mobile-release`: só o recorte build/flavor/push/conta, apontando ao piso 18 da engineering; numeração unificada (SKILL.md e CLAUDE.md, pisos 1–11).
- Novo `scripts/check-mobile-effects.sh` (+ teste vermelho→verde): cumpre o grep prometido em `entrega-lojas.md` §7.3 em `fastlane/`, `.maestro/`, `*.yaml`, `*.xcconfig`, `*.plist`, `*.entitlements` e, com `--nonprd`, barra `aps-environment=production`. O `check-external-effects.sh` herdado não foi editado (o sync o sobrescreve).

### Adicionado
- Bloco "Herda os pisos 22–29 da `schematize-engineering`" em SKILL.md e `assets/CLAUDE.md`.

### Pendente (`[~]`)
- P1-15 (resto): gate sobre o ARTEFATO assinado (`plutil`/`aapt dump`, `targetSdk`, 16 KB, `exported`) — exige ferramentas de SDK ausentes aqui, não testável.
- P1-17 / P1-9: exigência de Xcode/SDK da App Store, verificação de desenvolvedor Android, Play Integrity vs SafetyNet — sem fonte oficial confirmada nesta rodada.

## [0.7.0] — 2026-10-14
Integração com a nova `schematize-iam`: o IAM mobile aponta para o broker em vez de recopiá-lo; gate da skill-dev verde.

### Alterado
- `references/iam-mobile.md`, `assets/commands/mobile-auth.md`, `SKILL.md` e `assets/CLAUDE.md` apontam para `schematize-iam → references/protocolos.md`/`fatores.md`/`sessao.md`/`topologia.md` e para o gate `schematize-iam → scripts/check-iam.sh`; fica aqui só o que é do cliente nativo (deep link, secure storage, biometria, passkey de plataforma). Motivo: a spec do broker passou a ter dona, e duas cópias divergem.
- Blocos herdados `engineering/precedencia` (variante `dominio`) e `engineering/orquestracao` inseridos onde faltavam e sincronizados (`tools/sync-herdados.mjs`).
- Description reduzida para ≤190 caracteres (orçamento do catálogo, 45 skills).

## [0.6.1] — 2026-10-14
Ressincronização dos blocos herdados com a engineering v0.27.0; sem mudança de piso próprio.

### Alterado
- Description reduzida (≤235 chars) para caber no orçamento de listagem de skills (soma ≤8300); mesmo território, fronteiras com as irmãs preservadas.
- Blocos herdados ressincronizados com a `schematize-engineering` v0.27.0 (`tools/sync-herdados.mjs`): orquestração com a regra de imagem (nunca pelo Claude; detecta Codex/Gemini e pergunta ao usuário qual usar, Codex como sugestão) e `schematize overdev delegar` (comando do app) no lugar do falso nome de skill `schematize-overdev`.

## [0.6.0] — 2026-10-14
Corte de Target API vigente, ponteiros corrigidos, divisão de mando com as skills de linguagem.

### Corrigido
- `references/entrega-lojas.md`: citava `references/auto-update.md`, que só existe na desktop; agora `schematize-desktop → references/auto-update.md`.
- `references/stack-versoes.md`: o corte de 31/08/2026 (API 36) já passou; passa a "vigente", com extensão até 01/11/2026 e isenção de app privado (doc oficial do Android). Próximo corte marcado `<!-- reverificar -->`.
- `SKILL.md`: ponteiros para `schematize-swift`, `schematize-kotlin` e `schematize-dart`; a mobile manda em auth/offline/push/loja, as de linguagem no código.
- `description` com 350 caracteres ou menos (era 1010).
- **Description** reduzida (~270 chars) para caber no orçamento de listagem (soma das 31 skills ≤ 8500; o Claude Code corta a listagem acima disso).

### Alterado
- `scripts/check-external-effects{,.test}.sh` viram arquivos herdados da engineering (cabeçalho "herdado de schematize-engineering — não edite aqui"); conteúdo inalterado.

## [0.5.2] — 2026-09-30
O piso de orquestração passa a ser **herdado** da base em vez de copiado à mão: uma mudança na engineering não exige mais editar 38 arquivos.

### Alterado
- Piso "Orquestrador não desenvolve; subagent barato executa" em `assets/CLAUDE.md` e `SKILL.md` agora é um bloco `<!-- herdado:engineering/orquestracao:… -->`, sincronizado de `schematize-engineering/assets/herdados/orquestracao.md` por `tools/sync-herdados.mjs` (checado no CI). Redação normalizada; conteúdo inalterado.

### Mantido (piso inalterado)
- Sonnet por default, escada até opus, sem frota ociosa (engineering `references/orquestracao.md` §9/§9.6).

## [0.5.1] — 2026-09-30
Pedido do dono: agents idle poluem a tela e seguram recurso.

### Adicionado
- Piso de orquestração ganha a regra de frota ociosa (idle com pendência volta ao trabalho; dependente de outro agent → mata e enfileira com gatilho; terminou → mata); detalhe na `schematize-engineering` §9.6.

## [0.5.0] — 2026-09-30
Pedido do dono: **custo** — orquestrador em modelo padrão não desenvolve; micro-tasks baratas; `sonnet` como default nos subagents, `opus` só após falha.

### Adicionado
- **Piso "Orquestrador não desenvolve; subagent barato executa"** (`assets/CLAUDE.md` e `SKILL.md`), com remissão à normativa em `schematize-engineering` → `references/orquestracao.md` §9. O agent principal só **planeja, decompõe, despacha, supervisiona e revisa**; ação onerosa vira **micro-tasks**; subagents em **`sonnet`** por padrão e a escada é *mesmo subagent corrige (até 2 rodadas) → re-decompõe → só então `opus`*, com motivo no checkpoint. No **overdev**, cada item do checklist é executado por subagent `sonnet` e revisado pelo principal.

### Mantido (piso inalterado)
- Todos os pisos anteriores seguem valendo sem afrouxamento; a regra nova só define **quem executa** e a que custo, não o que é exigido.

## [0.4.0] — 2026-08-21
Segunda leva do saneamento: as lacunas de escopo do inventário da vistoria.

### Adicionado
- **`offline-sync.md` §3.1 — o sync-token é um CONTRATO**: opaco (*o cliente que "sabia" o que o token significava quebra quando o servidor muda a estratégia — e ele está **instalado***), monotônico, **expirável com `410 Gone` ⇒ full resync** (*devolver 200 com delta incompleto é como o cliente fica com um estado que nunca converge, e ninguém descobre porque não há erro*), retenção declarada e idempotência dos dois lados. Mais o **ciclo de vida do tombstone**, com a regra que amarra os números: **TTL do tombstone ≥ janela do sync-token**.
- **`offline-sync.md` §3.2 — migração do schema local e da outbox**, onde **não há rollback no device**: migração para frente **testada a partir da versão publicada**; **a outbox migra junto** (o app novo abre fila escrita pelo app velho — versione cada item ou drene antes, sabendo que drenar exige rede); **nunca descartar a fila em silêncio** (quarentena visível — mutação que some sem rastro é o "salvou" que virou mentira); versão checada no boot, com o app antigo **recusando** banco novo.
- **`plataforma.md` §4.1 — i18n e localização**, com o argumento que falta em quase todo time: *no web você troca o texto e faz deploy; no app a string errada **está instalada***. Plural pelo mecanismo da plataforma (a regra do polonês não é binária), placeholder posicional, formato pelo locale, **locale por app**, pseudo-locale e RTL no fontScale máximo.
- **`entrega-lojas.md` §3.1 — forced update e `min_supported_version`**, o único "rollback" real: as três alavancas (halt do rollout · **kill-switch de feature**, que precisa existir **antes** do incidente · forced update), com endpoint de política **independente do que quebrou**, **fail-open** quando ele não responde, `min_supported` ≠ `recommended`, e o caminho **ensaiado**.
- **`performance.md` §3.1 — execução em background é POLÍTICA do SO**: App Standby Buckets (o mesmo código com comportamento diferente **por usuário**), Doze, alarme exato com permissão, **FGS com `type` (Android 14+)**, restrições de fabricante, e no iOS o fato de que `BGTask` é **oportunista, sem garantia**. MUST: background **idempotente, retomável e observável**, e produto que **não depende** dele para função essencial.

### Mudado
- **React Native no rol passou a dizer "New Architecture"** (padrão desde a 0.76), com o que isso muda na **decisão de fit**: biblioteca sem suporte é **dívida com prazo**, migrar é **projeto com ADR**, e *comparar RN "pelo que ele era" é comparar com um produto que não existe mais*.
- README com a contagem de pisos corrigida (8 → 9) — hoje verificada pela regra `contagem` do lint do catálogo.

## [0.3.0] — 2026-08-21
As duas promessas de primeira linha que a vistoria de 2026-08-21 achou vazias: *"o mesmo piso, incluindo **testes**"* entregava **9 linhas** dentro de `offline-sync.md`, e **push** — promessa da 1ª linha da description — entregava 17 linhas sem rotação de token, sem `POST_NOTIFICATIONS` e sem limpeza de token morto.

### Adicionado
- **`references/testes-mobile.md`** — o capítulo de testes, **como ponteiro**: a pirâmide, o teste de comportamento e o flaky continuam sendo da `schematize-qa`; aqui fica o que o **dispositivo** muda. Fronteiras da pirâmide no app (unidade sem `Context`/`UIApplication`), **matriz de dispositivos escrita e datada** (piso e teto de SO no CI, o parque real por analytics, os extremos que quebram layout), e os casos que não existem no servidor: permissão negada **nos três estados**, deep link com app fechado/em background/**deslogado**/adulterado, **migração do banco local a partir da versão anterior** (teste que cria o banco do zero **não** testa migração — a condição vacuamente verdadeira do mobile, e no device do usuário **não há rollback**), upgrade com estado, processo morto pelo SO, **rede ruim e não ausente**, relógio/fuso/locale adversos, disco cheio, a11y no fontScale máximo.
- **`/mobile-test`** — o comando que exercita esse capítulo.
- **`references/performance.md` §4 — ciclo de vida do token de push:** rotação (o token **não é estável**: reinstalação, restauração de backup, limpeza de dados, atualização; re-registro **em toda abertura**, substituindo o registro anterior) · **logout e troca de usuário apagam o token no servidor ANTES de encerrar a sessão** — token que sobrevive ao logout manda push do usuário antigo para quem entrou depois · **`POST_NOTIFICATIONS`**, permissão de runtime desde o **Android 13 (API 33, 2022)**: em `targetSdk` ≥ 33 sem o pedido o app **simplesmente não notifica, e nenhum erro aparece no log** · **limpeza de token morto** pela resposta do provedor (`Unregistered`/`410`/`UNREGISTERED`) — sem isso a base incha, a taxa de erro sobe e o provedor limita o canal inteiro: o push que importa (OTP, alerta) para de chegar por causa do que não importava.
- **`references/performance.md` §4.1 — push entra na suíte**: 10 casos contra **servidor falso de APNs/FCM**, porque push não se testa mandando push (efeito externo não sai de não-produção).

### Mudado
- `SKILL.md` e `/mobile-load` passam a listar o novo reference; o fluxo de uso ganhou o passo "teste como app, não como servidor".

## [0.2.0] — 2026-08-20

Propaga pro recorte mobile o piso **"efeito externo NUNCA sai de não-produção"** — normativo em
`schematize-engineering` → `references/efeitos-externos.md`. No mobile o dano é maior: um build de
teste que aponta pra produção dispara efeito **real a partir de milhares de devices de testadores**,
e o app **já está distribuído** — não existe rollback de binário instalado.

### Adicionado
- **SKILL.md** — piso inegociável **9**: build de dev/QA/TestFlight/internal track/App Distribution
  **nunca** aponta pro backend de prd nem pro provedor real (ambiente por **build configuration /
  flavor / scheme**, resolvido no build, **fail-closed**); **push em sandbox** (APNs
  `aps-environment: development` + **projeto FCM de teste**); conta de teste/review em domínio de
  **ROTA NULA**; **E2E de Email OTP lido no sink**. Linha nova no mapa de references e menção na
  `description`.
- **references/entrega-lojas.md §7** (novo) — "build de teste NUNCA fala com produção": ambiente é
  build configuration e não `if` em runtime (**vetado** toggle de ambiente em runtime/config
  remota), **gate no CI sobre o artefato assinado** (URL de prd, plist/`google-services.json` de
  produção, `aps-environment` errado, chave de prd), **tabela trilho → backend/push/e-mail**, push
  em sandbox com o caso do **TestFlight** (perfil de distribuição não tem APNs sandbox → o
  isolamento passa pro **remetente**, e o backend de prd recusa token de build de não-prd), conta de
  teste/persona/fixture/**review de loja** em `test.<domain>` de rota nula, e o **multiplicador do
  device farm** (cap por execução conta a matriz inteira).
- **references/iam-mobile.md §8** (novo) — identidade: toda conta não-humana em domínio de rota nula
  (**vetado** `@gmail.com`, e-mail do testador/da equipe, domínio de prd); **Email OTP always-on
  exercido contra o SINK** (Mailpit, API HTTP) no E2E de cadastro/login; guard deny-by-default no
  provider do IdP + cap; SMS/voz com magic numbers; conta de review com **OTP pré-provisionado
  escopado + ADR** ou demo mode, nunca caixa real do time.
- **DoD/checklists** — 3 itens novos na DoD de release (`entrega-lojas.md`, agora §8) e 2 no
  checklist de IAM mobile, todos com prova exigida.
- **assets/CLAUDE.md** — piso sempre-on **8** com o mesmo veto, o "por quê" (reputação queimada
  derruba o **OTP de login** de produção) e o ponteiro pra normativa.

### Mudado
- `references/entrega-lojas.md`: a **DoD de release** passou de §7 para **§8** (o §7 agora é efeito
  externo); §5 (review) remete ao §7 pro endereço da conta de review.
- `references/performance.md` §4: registro de push token carrega `env`/`build_id` e o backend de prd
  **recusa** token de build de não-prd.
- `/mobile-release`: novo bloco de auditoria de efeito externo e referência da DoD atualizada (§8);
  build de não-prd apontando pra produção **não fecha** o release.

## [0.1.0] — 2026-08-15

Primeira versão da skill de **engenharia de apps mobile** da casa — o mesmo piso da
`schematize-engineering` (segurança, IAM, testes, ops, DoD §35, archive §28, índice §39) aplicado
ao recorte mobile (iOS/Android/cross), sob as duas verdades novas: o dispositivo é **cliente
hostil** e a rede é **offline por padrão**. Muda o "como", não o "o quê".

### Adicionado
- **SKILL.md** com 8 pisos inegociáveis (piso da casa é o mesmo; nunca segredo no bundle; auth
  delegada ao IdP no servidor; secure storage sem vazamento; passkeys+biometria no núcleo com
  biometria≠autorização e logout irreversível; offline-first com outbox e conflito explícito;
  release com rollout gradual + gate; device é território hostil com defesa em profundidade) +
  mapa de references + relação com engineering/backend/web/pentest/audit.
- **references/**:
  - `plataforma.md` — rol de plataformas sancionadas (Swift/Kotlin nativo, KMP/Flutter/RN cross),
    escolha por **fit + ADR** (espelha `linguagens.md`), arquitetura interna em camadas, app como
    cliente do backend/IdP da casa.
  - `offline-sync.md` — offline-first (UI lê do local), **outbox** durável de mutações,
    idempotência, delta sync, tombstones, **resolução de conflito explícita** (LWW/merge/CRDT/
    servidor-autoritativo), UX de estado de rede, testes de reconciliação.
  - `iam-mobile.md` — IAM mobile **casado com o `iam.md`**: public client OIDC/PKCE ao
    `auth.<domain>`, deep link verificado (Universal/App Links, não WebView), passkeys+biometria,
    secure storage (Keychain/Keystore), logout irreversível, authz no servidor, checklist DoD.
  - `seguranca-mobile.md` — cliente hostil: **nunca segredo no bundle**, TLS+SPKI pinning com
    backup, root/jailbreak+attestation como **sinal**, ofuscação sensata, dado cifrado em repouso,
    deep link/IPC como entrada hostil, SDKs de terceiro, permissões mínimas.
  - `entrega-lojas.md` — assinatura em cofre, build assinado no CI, trilhos de release,
    **staged/phased rollout** com gate de crash-free/ANR e **halt**, OTA de JS/config dentro das
    regras, review guidelines, observabilidade/crash sem PII, DoD de release.
  - `performance.md` — cold start/main thread, bateria (WorkManager/BGTaskScheduler), rede (delta/
    coalescing/cache), **push notifications** (APNs/FCM, token atado à sessão, payload é gatilho),
    tamanho do app, perfilar antes de otimizar.
- **assets/commands/**: `/mobile-help`, `/mobile-load`, `/mobile-auth`, `/mobile-offline`,
  `/mobile-release`, `/mobile-claude`, `/mobile-cc`, `/mobile-handoff`.
- **assets/CLAUDE.md** — regra sempre-on: o piso da casa é o mesmo; nunca segredo no bundle; auth
  delegada ao IdP; secure storage; offline-first sem perder escrita; rollout gradual com gate.
