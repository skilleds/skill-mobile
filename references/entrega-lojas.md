<!-- cross-skill: efeitos-externos.md, entrega.md, observabilidade.md, ops.md -> schematize-engineering -->
# Entrega nas lojas — assinatura, rollout, OTA, review, observabilidade

> A entrega da casa (`entrega.md`, DoD §35, archive §28) vale inteira no mobile; o que muda é que
> **entre o seu commit e o usuário existe uma loja** (App Store / Play) com **revisão humana,
> assinatura criptográfica e rollout gradual**. Publicar app é operação de **ops** com gate, não
> "sobe e reza". E o binário na mão do usuário **não dá rollback instantâneo** — por isso rollout
> gradual e observabilidade são inegociáveis.

## 1. Assinatura e credenciais de publicação — segredo de ops

- **Chaves de assinatura são segredo crítico (`seguranca-mobile.md`, `ops.md`):** a **upload/app
  signing key (Android)** e os **certificados/perfis (iOS)** vivem em cofre (não no repo, não no
  laptop do dev). Perder a chave Android = não conseguir mais atualizar o app.
- **Play App Signing** (Google gerencia a chave de assinatura) e **assinatura gerenciada da Apple**
  quando possível — reduz o raio de perda. Credenciais de CI (App Store Connect API key, service
  account) em secret manager, com rotação.
- **Build de release reprodutível e assinado pelo pipeline**, não na máquina de alguém. O artefato
  que vai pra loja é o que o pipeline produziu e registrou (rastreável ao commit — casa com o
  archive §28).

### 1.1 Gatilho de CI (piso 27 da `schematize-engineering`)

- **Por commit o gate é LOCAL** (`scripts/check-*.sh`, unit/UI no simulador local). **Build assinado,
  matriz de devices e device farm NÃO rodam por commit nem por PR** (VETADO `pull_request` e `push`
  em branch): são caros, usam segredo de assinatura e multiplicam disparo (§7.4).
- **O CI remoto só dispara** por `workflow_dispatch`, por tag `hml-*`/`v*` (antes de promover a hml
  ou de ir à loja) ou a pedido do usuário; `concurrency` com `cancel-in-progress: true` e
  `paths-ignore` de docs/`*.md`.
- Onde este reference diz "no CI", leia: **no pipeline de tag/hml ou a pedido** — nunca por commit.

## 2. Versionamento e trilhos de release

- **SemVer visível** (versão de marketing) **+ build number monotônico** (sobe sempre, nunca
  reusa). Loja rejeita build number repetido.
- **Trilhos/tracks:** `internal → closed/TestFlight → open beta → production`. Nada vai direto pra
  produção sem passar por um trilho de teste com usuários reais de teste.
- **Cada release tem changelog e archive:** o que mudou, qual commit, qual resultado do rollout —
  no `_archive` (§28). Release sem rastro não aconteceu.

## 3. Staged/phased rollout — nunca 100% de uma vez

- **Rollout gradual obrigatório:** Play **staged rollout** (1% → 5% → 20% → 50% → 100%) e iOS
  **phased release** (7 dias). Você **observa crash/ANR/erro** entre os degraus e **segura/halt** se
  a métrica piorar.
- **Gate de promoção:** só sobe o degrau se crash-free e métricas de negócio estão sãos vs. a versão
  anterior. Regressão → **halt rollout** (Play) — para novos usuários, contém o dano.
- **Rollback é caro no mobile:** você **não** "volta a versão" no device do usuário; você **halta** o
  rollout e publica um **hotfix pra frente** (nova versão). Por isso o gradual é a rede de segurança
  — o estrago fica contido em % pequeno.

## 3.1 Forced update e `min_supported_version` — o único "rollback" real

Quando o binário **já está distribuído**, não existe rollback: a versão ruim está no aparelho de
quem já atualizou, e a loja não a desinstala. O que existe é **parar a hemorragia** — e são três
alavancas, com custos diferentes:

1. **Halt do rollout** (`schematize-mobile` §3): interrompe a distribuição para **quem ainda não
   recebeu**. É a primeira e a mais barata, e não faz nada por quem já está com a versão ruim.
2. **Kill-switch de feature** (flag remota, com default seguro): desliga **o que quebrou** sem
   depender de atualização. É o que salva o dia — e por isso a flag precisa existir **antes** do
   incidente.
3. **Forced update:** o app consulta, no boot, um endpoint de política
   (`min_supported_version` + `recommended_version`) e, abaixo do mínimo, **bloqueia** com uma tela
   que leva à loja.

**MUST**, se você vai ter forced update (e todo app que fala com API versionada vai precisar um dia):

- **O endpoint de política é servido, não embutido** — e ele **não pode depender do que quebrou**
  (nada de exigir login para saber se o app pode abrir).
- **Fail-open com cuidado:** se a política não responde, o app **abre** — senão uma indisponibilidade
  sua vira "o app de todo mundo parou". A exceção é o bloqueio por **segurança**, que é fail-closed
  e precisa estar previsto.
- **Distinga `min_supported` de `recommended`:** o primeiro **bloqueia**, o segundo **sugere**.
  Bloquear por conveniência (para "todo mundo estar na última") é hostil e vira desinstalação.
- **A tela de bloqueio é usável offline** e diz **por quê** — e leva à loja com um toque.
- **Teste o caminho:** subir o `min_supported_version` é uma operação de incidente; ela precisa ter
  sido ensaiada, senão você a descobre no pior dia. (Casa com o piso do drill da
  `schematize-infra`: procedimento que nunca foi executado não é procedimento.)

## 4. OTA (over-the-air) — quando aplicável e dentro das regras

- **OTA de conteúdo/config sempre:** feature flags, config remota, kill-switch de feature, conteúdo
  — atualizáveis sem release de loja. **Kill-switch** de feature nova é piso: liga/desliga sem
  esperar review.
- **OTA de código JS (RN — `expo-updates`/EAS Update)** é legítimo **para JS bundle**, dentro das regras das
  lojas (abaixo). ✔ **2026-08-21: `CodePush` (App Center) foi APOSENTADO em 31/03/2025** junto com o App Center.
  Quem ainda depende dele tem um caminho de release que **não existe mais** — migrar é tarefa, não
  opinião. O padrão vivo é o **`expo-updates`/EAS Update** (ou um servidor de updates próprio
  compatível). Vale o mesmo piso de sempre: OTA entrega **bundle JS**, nunca código nativo, e
  **regras das lojas**: OTA **não** pode mudar propósito/comportamento aprovado do app nem burlar a
  review (Apple 2.5.2 / Google). Correção de bug e ajuste de UI: ok. "App novo por OTA": violação.
- **OTA assinado e versionado:** o pacote OTA é assinado e casado a uma faixa de versão nativa
  (bundle novo em binário antigo pode crashar) — teste de compatibilidade antes de empurrar.
- **Native precisa de review:** mudança de código nativo, permissão nova, SDK novo → passa pela loja.
  Não existe OTA de binário nativo.
- **No OTA, VOCÊ é a loja.** A revisão que a App Store/Play faz não acontece no bundle JS — então o
  piso de distribuição volta inteiro para o time: **update assinado, verificado antes de aplicar,
  com pin de versão e rollback testado**. É o mesmo piso que a **`schematize-desktop`** detalha
  (`schematize-desktop → references/auto-update.md`), pelo mesmo motivo: quando não há loja no caminho, quem garante a
  integridade do artefato é você.

## 4.1 Requisitos de plataforma com PRAZO — o que reprova o upload

> Estes três não são "boas práticas": são **gates de upload**, com
> data. Faltavam inteiros nesta skill — e o modo de falha deles é o pior possível para uma equipe
> mobile: o app **pronto** não sobe, no dia do release.

**Os valores (target API, 16 KB, privacy manifest, datas) moram só em `stack-versoes.md`** — tabela
canônica, com data de verificação. Aqui fica o que fazer com eles:

**O que fazer com isso — e é o ponto:**

- **A data entra no calendário do time, não na memória de alguém.** O corte de 31/08 do Play é
  anual e **não avisa**: quem descobre no dia do release perde o release. Ponha um lembrete
  recorrente e trate o bump de `targetSdk` como **tarefa de manutenção agendada**, com teste de
  regressão dos comportamentos que a nova API muda.
- **16 KB é problema de DEPENDÊNCIA, não só seu.** Um `.so` de SDK de terceiro desalinhado reprova
  o seu upload. Cheque (`zipalign -c -P 16` / verificação de alinhamento do AGP, no build de tag/hml) **antes** do
  dia do release, e trate SDK que não alinha como bloqueio de dependência
  (`schematize-engineering` → `references/cadeia-suprimentos.md`).
- **O privacy manifest é do app E dos SDKs.** O seu você escreve; o do SDK de terceiro você
  **exige** — SDK sem manifest/assinatura vira item de cadeia de suprimentos, não "problema do
  fornecedor".
- **Os três entram na DoD de release** (`SKILL.md` §"Definition of Done"): não é "pronto" se o
  upload seria recusado hoje.

## 5. Review guidelines — projete pra passar

- **Conheça as regras antes de construir:** App Store Review Guidelines e Google Play Policies são
  requisito, não surpresa. Login obrigatório sem valor demonstrável, **Sign in with Apple** quando há
  login social de terceiro, permissão sem justificativa,
  privacy label errada, conteúdo gerado sem moderação → **rejeição**.
- **Pagamento de bem digital: NÃO é mais "fora do IAP = rejeição" como absoluto.** ✔ Verificado em
  2026-08-21. Duas frentes mudaram a regra e ela **varia por jurisdição**: o **DMA** na União
  Europeia (steering e lojas alternativas) e a decisão de **Epic v. Apple** nos EUA (link-out para
  compra externa). Hoje a pergunta certa não é *"pode?"* e sim *"em qual mercado, com qual
  mecanismo, e sob quais regras de steering?"* — e a resposta **muda com o tempo e com o país**.
  **Piso da casa:** decida por **mercado**, registre em **ADR** (é decisão de produto com risco de
  loja), e confira a diretriz vigente **antes de cada submissão** — não de memória. Um absoluto
  errado aqui custa nas duas direções: derruba receita legítima na UE, ou derruba o app onde a
  regra antiga ainda vale.
- **Privacy é gate de loja:** App Privacy (Apple) / Data safety (Google) preenchidos com a verdade;
  **ATT (App Tracking Transparency)** no iOS quando há tracking; peça permissão **just-in-time**.

  **Purpose string honesta** (as `NS*UsageDescription` do iOS e o texto que acompanha o pedido no
  Android) é requisito de review **e** de UX, e as duas coisas puxam para o mesmo lado: diga **o
  que o app faz com aquilo**, na primeira pessoa do usuário e em uma frase — *"para anexar a foto do
  comprovante ao seu pedido"*, não *"o app precisa de acesso à câmera"*. Genérica, vazia ou copiada
  de exemplo **reprova no review**; e no aparelho ela aparece no **momento** em que a pessoa decide,
  então uma frase ruim custa a permissão. Declare **só o que você usa de fato** — permissão declarada
  e não usada é rejeição por si só, e é o resíduo clássico de biblioteca que saiu do projeto e
  deixou a chave no `Info.plist`/manifest. Os três estados da recusa (incluindo *negada
  permanentemente*) têm teste próprio em `testes-mobile.md` §3.
- **Conta de teste e demo:** forneça credenciais/roteiro pro revisor (senão rejeita por "não
  consegui testar"). Guest mode ou deep link de demo ajuda. O **endereço** dessa conta obedece ao
  §7 (domínio de teste em rota nula) — conta de review apontando pra caixa real do time é vetada.

## 6. Observabilidade e crash — o app está longe, você precisa enxergar

- **Crash + ANR reporting obrigatório** (Crashlytics/Sentry/nativo): stack simbolicada (suba
  **dSYM/mapping/ProGuard map** no release), crash-free users/sessions como métrica de gate do
  rollout (§3).
- **Sem PII/segredo na telemetria:** scrub de token, email, dado de cliente de logs, breadcrumbs e
  crash reports (`iam-mobile.md` §4). Telemetria é dado que sai do device — trate como export.
- **Métricas de UX/negócio:** cold start, tempo até interativo, taxa de sucesso de sync, falhas de
  rede, funil — casam com a observabilidade LGTM+ da casa (`observabilidade.md`).
- **Consentimento e privacidade:** analytics respeita opt-out/ATT; mínimo necessário; nada de
  fingerprinting escondido (é rejeição de loja e violação de confiança).

## 7. Efeito externo fora de produção — build de teste NUNCA fala com produção

> **Normativa:** `schematize-engineering` → `references/efeitos-externos.md` (domínio de teste em
> **rota nula**, **sink** por default, **guard deny-by-default dentro do provider**, **cap por
> execução**, chave **sandbox**). Aqui só o **recorte mobile** — que é o mais caro da casa: quando
> um build de não-produção "vaza" pra produção, o disparo real não sai de um servidor, sai de
> **milhares de devices de testadores**, cada um com sua sessão e seu push token. E o app **já
> está distribuído**: não existe `rollout undo` de binário instalado (§3) — o melhor que se
> consegue é **halt** + hotfix pra frente, com o build ruim ainda rodando na mão de quem baixou.

### 7.1 Ambiente é build configuration — não `if` em runtime

- **Base URL do backend, `client_id` do IdP e TODA chave de provedor** (push, analytics, PSP,
  mapas, e-mail/SMS) são resolvidos **no build**: **scheme + build configuration/`xcconfig`** no
  iOS, **product flavor + buildType** no Android, `--dart-define`/env por perfil no cross.
  **VETADO** decidir ambiente por `if` lido de config remota, de `UserDefaults`/`SharedPreferences`
  ou de um toggle na tela de debug — toggle em runtime é exatamente o caminho pelo qual um
  TestFlight acaba apontando pra `prd`.
- **Fail-closed:** config de ambiente ausente ou ilegível ⇒ o build **assume não-prd** e usa o
  stack de teste. Nunca o contrário. Build que não sabe onde está **não fala com produção**.
- **Gate sobre o ARTEFATO assinado** (não sobre o código; roda no build de tag/hml, §1.1): o job de build de não-prd
  **falha** se o `.ipa`/`.aab` contiver a base URL de prd, o `GoogleService-Info.plist`/
  `google-services.json` de **produção**, `aps-environment: production` num build de dev, ou
  qualquer chave de provedor de prd (`plutil`/`aapt dump`/`strings` + grep).

| Trilho / build | Backend | Push | E-mail/SMS/PSP |
|---|---|---|---|
| debug/dev local | `api.dev.<domain>` ou local | APNs **sandbox** (`aps-environment: development`) + **projeto FCM de teste** | **sink** (Mailpit) / magic numbers / chave de teste |
| QA, `internal` track, Firebase App Distribution | `api.hml.<domain>` | **projeto FCM de teste**; APNs pelo **remetente de hml** (chave/topic próprios) | **sink** / chave de teste |
| TestFlight, `closed` beta | `api.hml.<domain>` — **nunca** prd | idem hml (o build é assinado com perfil de distribuição, ver 7.2) | **sink** / chave de teste |
| `open` beta e produção | `api.<domain>` | APNs **produção** + FCM de produção | provedor real |

### 7.2 Push em sandbox — e o que fazer quando o TestFlight não deixa

- **Dev/QA:** APNs em **sandbox** (chave/certificado de desenvolvimento, entitlement
  `aps-environment: development`) e **projeto FCM separado** de teste. **VETADO** embarcar o
  `GoogleService-Info.plist`/`google-services.json` de **produção** em build de QA/TestFlight — é
  o vazamento mais silencioso que existe: compila, roda, e um dia manda push de verdade.
- **TestFlight/ad-hoc não têm APNs sandbox:** o perfil de distribuição carrega
  `aps-environment: production` por construção. Logo, o isolamento **muda de lado**: é o
  **remetente** que separa — o build de TestFlight registra o token no **backend de hml**, e só
  hml tem a chave APNs/o projeto FCM que fala com aqueles tokens. O backend de **prd rejeita**
  token registrado por build de não-prd — o registro do token (que já é **atado à sessão**,
  `performance.md` §4) carrega também `env` e `build_id`, e o mismatch é **recusa**. Sem essa separação no servidor, um push de campanha de prd chega em **usuário real** pelo
  device do testador.
- **Push é efeito externo como e-mail:** entra no mesmo cap por execução e no mesmo guard
  deny-by-default do provider (`efeitos-externos.md` §2/§4).

### 7.3 Conta de teste — endereço em ROTA NULA, sempre

- Seed de QA, **persona de screenshot** (fastlane snapshot), **fixture de UI test** (XCUITest/
  Espresso/Maestro), usuário de carga e conta de demo usam
  `<papel>+<run-id>-<n>@test.<domain>` (null MX RFC 7505 + SPF `-all` + DMARC `p=reject`) ou TLD
  reservado (`.test`/`.invalid`/`.example`). **VETADO**: `@gmail.com` e afins, o e-mail **do
  testador ou de alguém da equipe**, o domínio do cliente e o **domínio de produção**.
- **Conta de review da loja** é caso **nominal**, não exceção livre: e-mail no domínio de teste e o
  2º fator resolvido por **OTP pré-provisionado escopado àquela conta** (com expiração e **ADR**,
  §27) ou por **demo mode** — nunca apontando a conta de review pra uma caixa real do time. O
  detalhe de identidade está em `iam-mobile.md` §8.
- **O gate local trava** `gmail|hotmail|outlook|yahoo|icloud` em `*Tests/`, `fixtures/`, `seed*/` e
  nos arquivos de fastlane/Maestro/`*.yaml`/`*.xcconfig`/`*.plist`
  (`scripts/check-mobile-effects.sh`, por commit).

### 7.4 O multiplicador do mobile: device farm

O cap por execução e o guard no provider valem inteiros (`efeitos-externos.md`) — com um agravante
daqui: uma suíte de UI test que faz "cria conta → recebe OTP → loga" roda **uma vez por device da
matriz**. Uma matriz de 12 devices no Firebase Test Lab/Sauce/BrowserStack (que só roda em tag/hml ou a pedido, §1.1) multiplica o disparo por
12 **sem ninguém notar**. Portanto: o cap conta **a execução inteira da matriz** (mesmo `run_id`
propagado pra todos os shards), e o E2E de OTP lê o código no **sink** (`iam-mobile.md` §8), não em
caixa nenhuma.

## 8. DoD de release mobile (soma à DoD §35)

- [ ] Build de release **assinado pelo pipeline de tag** (§1.1), rastreável ao commit; chaves em cofre.
- [ ] Version/build number corretos; changelog + archive (§28) do release.
- [ ] Passou por **trilho de teste** (TestFlight/closed track) antes de produção.
- [ ] **Staged/phased rollout** configurado com gate de crash-free/ANR e plano de **halt**.
- [ ] **Kill-switch/flags** da feature nova; OTA (se houver) dentro das regras da loja e
  compatível com a faixa de versão nativa.
- [ ] **Crash/ANR** com símbolos subidos; telemetria **sem PII/segredo**; privacy labels/ATT/permissões corretas.
- [ ] Conta/roteiro de **review** preparados; regras da loja verificadas.
- [ ] **Build de não-prd não fala com produção** (§7): base URL/`client_id`/chaves por build
  configuration ou flavor, **fail-closed**, e o **artefato assinado** inspecionado no pipeline de tag/hml (nada de
  URL de prd, plist/json de FCM de produção ou chave de provedor de prd).
- [ ] **Push isolado**: projeto FCM de teste / APNs sandbox em dev-QA; token registrado por build de
  não-prd **rejeitado** pelo backend de prd.
- [ ] **Endereços de conta de teste/review/persona/fixture só em `test.<domain>` (rota nula)** ou TLD
  reservado; o gate local trava caixa real. E2E de Email OTP lê o código no **sink**
  (`iam-mobile.md` §8), com **cap por execução** válido pra matriz inteira do device farm.
