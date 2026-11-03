<!-- cross-skill: iam.md -> schematize-engineering -->
<!-- cross-skill: protocolos.md, fatores.md, sessao.md, topologia.md -> schematize-iam -->
# IAM no mobile — o mesmo piso da casa, no cliente hostil

> **Dono do broker: `schematize-iam`.** O desenho do `auth.<domain>` (authorization code + PKCE passo a
> passo, tokens e JWKS, fatores e passkeys, sessão e logout, recuperação) vive lá: `schematize-iam →
> references/protocolos.md`, `schematize-iam → references/fatores.md`, `schematize-iam →
> references/sessao.md`, `schematize-iam → references/topologia.md` (fluxo por tipo de cliente). Este
> arquivo guarda **só o que é do cliente nativo** (deep link, secure storage, biometria, passkey de
> plataforma) e aponta para lá o resto; o gate estático do IdP é `schematize-iam → scripts/check-iam.sh`.

> Este reference **não inventa** um IAM de mobile: ele **casa com o `iam.md`** da
> `schematize-engineering` (o piso agnóstico) e diz **como** aquele piso se realiza num app, onde
> o dispositivo é **território hostil**. Auth continua sendo uma **aplicação separada**
> (`auth.<domain>`, o IdP da casa); o app é só **mais um cliente OIDC**. A força continua sendo
> **≥2 fatores**, identidade ≠ email, ReBAC multi-tenant, enforcement **no servidor**. O que muda
> é o **como**: deep-link OIDC, secure storage, biometria, passkeys de plataforma.

## 1. O app delega ao IdP da casa — nunca implementa auth

- **VETADO** o app ter login próprio, guardar hash de senha, ou falar com o banco de usuários.
  Ele **redireciona** ao `auth.<domain>` por **OIDC/OAuth 2.1 + PKCE** e recebe tokens de volta,
  exatamente como o front web (`iam.md` §1). O IdP é o mesmo pra web, app e serviços.
- **Authorization Code + PKCE obrigatório** (nunca implicit flow, nunca ROPC/senha direta no app;
  o passo a passo é `schematize-iam → references/protocolos.md`). O `code_verifier` é gerado e
  guardado no device só durante o fluxo.
- **Segredo de client NÃO existe no app.** App é **public client** (não confidencial): não há
  `client_secret` no bundle — extrair o bundle é trivial. Segurança vem do PKCE + redirect
  registrado, não de um segredo embutido (`seguranca-mobile.md`, §"nunca segredo no bundle").

## 2. O retorno do fluxo — deep link seguro

- **Redirect por deep link:** use **Universal Links (iOS) / App Links (Android)** verificados por
  domínio (`apple-app-site-association` / `assetlinks.json` no servidor) — não `custom scheme`
  (`meuapp://`) sozinho, que **qualquer app pode sequestrar**. O link verificado prova posse do
  domínio e evita interceptação do `code`.
- **Fluxo no navegador do sistema:** use **ASWebAuthenticationSession (iOS) / Custom Tabs
  (Android)**, nunca uma `WebView` embutida — WebView permite ao app ler as credenciais digitadas
  e quebra SSO/passkeys. WebView de login é **vetado**.
- **`state` + PKCE** validados no retorno (anti-CSRF/anti-injeção de code).

## 3. Passkeys/WebAuthn + biometria — o núcleo (não roadmap)

Casa com `iam.md` §3 ("passkey é núcleo, já é 2 fatores num"):

- **Passkeys de plataforma:** **Passkeys (iOS, AuthenticationServices) / Credential Manager +
  Passkeys (Android)** são o fator forte de primeira classe — phishing-resistant, sincronizados
  pelo keychain da plataforma. O app oferece passkey no cadastro/login e no step-up.
- **Biometria (Face ID/Touch ID/BiometricPrompt) protege a chave, não substitui o servidor.** A
  biometria **desbloqueia localmente** a passkey/refresh no secure storage; ela é *gate local*,
  não um "logou no servidor". Autorização sensível ainda exige **step-up de verdade no IdP**
  (AAL alto, `iam.md` §3).
- **Nada de "biometria == autenticado" ingênuo:** biometria falsa/ausente cai no fluxo de fallback
  do IdP (Email OTP always-on, `iam.md`), nunca num bypass. E biometria **local** nunca autoriza,
  sozinha, ação sensível cross-tenant/billing — isso é step-up server-side.

## 4. Onde moram os tokens — secure storage, sempre

- **Refresh token e chaves em Keychain (iOS) / Keystore + EncryptedSharedPreferences (Android)** —
  respaldados por Secure Enclave/StrongBox quando disponível. **Nunca** em `UserDefaults`/
  `SharedPreferences` em claro, arquivo, log, ou `AsyncStorage`/`localStorage` de WebView.
- **Access token curto** (ex.: 15 min) + **refresh rotativo com detecção de reuso** (`iam.md` §6);
  o app renova silenciosamente — sessão longa (7d/90d device confiável) sem re-login constante,
  igual ao piso da casa.
- **Token nunca em log/crash report/analytics.** Scrub obrigatório do pipeline de observabilidade
  (`entrega-lojas.md`) — segredo em crash dump é vazamento.
- **Cifra em repouso:** dado sensível e a outbox (`offline-sync.md`) cifrados; chave no
  Keychain/Keystore, não hardcoded.

## 5. Logout, sessão e multi-dispositivo

- **Logout irreversível (`iam.md` §6):** não basta apagar o token local — **revoga o refresh
  (e a família) no IdP**, apaga a sessão server-side, e **desassocia o push token** do device.
  Depois do logout, replay do token guardado não reativa nada.
- **O device é uma sessão de 1ª classe:** aparece na view de dispositivos do IdP (rótulo, IP/geo,
  último uso), revogável remotamente ("sair deste aparelho"). Roubo de device → o dono revoga do
  web.
- **Push token atado à sessão:** ao deslogar/trocar de usuário, o push token é rotacionado — senão
  notificações do usuário A chegam no device agora do usuário B.

## 6. Authz continua no servidor — o app não é PDP

- **Deny-by-default no servidor; o app não decide permissão.** Esconder um botão no app é **UX**,
  não autorização. Todo endpoint valida a permissão no PEP server-side (ReBAC, `iam.md` §5). App
  que "confia" no que a tela mostrou é BOLA/BFLA esperando acontecer (`schematize-pentest`).
- **Token fino:** carrega `sub`/tenant/AAL/sessão, **não** a lista de permissões — authz é
  consultada/cacheada no servidor com TTL curto (evita authz stale num token longo de app).
- **Multi-tenant:** troca de tenant no app é troca de contexto **verificada no servidor** a cada
  request; o app nunca "vira admin" mexendo em estado local.

## 7. Risco e transversais (herda do `iam.md` §9)

- O **risk engine** do IdP vale pro app: device novo, geovelocidade impossível, jailbreak/root
  detectado (`seguranca-mobile.md`) alimentam o score → step-up/deceção server-side.
- **Notifica canais verificados** em login novo/troca de credencial; "não fui eu" revoga a sessão
  daquele device.
- **Migração de legado (prioridade 0):** app com login caseiro antigo → estrangula pro IdP da casa
  (re-hash preguiçoso, revoga sessões legadas, ativa Email OTP baseline) — `iam.md` §7.

## 8. Conta de teste, Email OTP e efeito externo — nada sai de não-produção

> **Normativa:** `schematize-engineering` → `references/efeitos-externos.md`. O recorte de
> **build/trilho/push** está em `entrega-lojas.md` §7; aqui só o que toca **identidade** — o
> endereço das contas não-humanas e o **fluxo de Email OTP** exercido ponta a ponta.

- **Toda conta não-humana usa o domínio de teste em ROTA NULA:** seed de QA, persona de
  screenshot, fixture de UI test, usuário de carga, conta de demo e conta de review da loja →
  `<papel>+<run-id>-<n>@test.<domain>` (null MX RFC 7505 + SPF `-all` + DMARC `p=reject`) ou TLD
  reservado (`.test`/`.invalid`/`.example`). **VETADO**: `@gmail.com` e afins, o e-mail **do
  testador ou de alguém da equipe (inclusive o seu)**, o domínio do cliente e o **domínio de
  produção**.
- **O Email OTP always-on** — o fator sempre disponível do IdP (`schematize-engineering` -> `references/iam.md` §3, "Fatores e níveis de garantia"; o §3 **deste** arquivo é passkeys/biometria) — **é justamente o que vira disparo em massa.** Todo E2E de
  cadastro/login em não-prd **lê o código na API HTTP do sink** (Mailpit): cria a conta, consulta o
  sink pelo destinatário, extrai o OTP, segue o fluxo. **Nunca** numa caixa real, **nunca** por
  "código fixo em produção". É isso que impede o laço "cria conta e faz login" — que num app roda a
  cada suíte e **uma vez por device da matriz** (`entrega-lojas.md` §7.4) — de virar milhares de
  e-mails reais, hard bounce e reputação de domínio queimada. Reputação queimada **tranca o
  usuário legítimo fora**: sem OTP entregue, não há login.
- **O guard mora no provider do IdP, não no teste:** destinatário fora do domínio de teste com
  `env != prd` → **erro** (fail-closed, config ausente = não-prd), **cap por execução** com abort,
  chave **sandbox**. O app não afrouxa isso do lado do cliente — quem envia é o `auth.<domain>`.
- **SMS/voz como fator:** mesmo piso — **magic numbers** do provedor + sink. Número de pessoa real
  (inclusive o seu) em fixture é **vetado**, e o SMS ainda **custa por unidade**.
- **Conta de review da loja:** e-mail no domínio de teste **e** o 2º fator resolvido por **OTP
  pré-provisionado escopado àquela conta** (com expiração e **ADR**) ou por **demo mode** — jamais
  apontando a conta de review pra uma caixa real do time só pra "o revisor conseguir entrar".

## Checklist mobile (entra na DoD quando o app tem auth)

- [ ] App é **public client OIDC/PKCE** delegando ao `auth.<domain>` — **sem** login próprio nem
  `client_secret` no bundle.
- [ ] Retorno por **Universal/App Links verificados** (não custom scheme cru); login no navegador
  do sistema (**não WebView**).
- [ ] **Passkeys de plataforma no núcleo**; **biometria desbloqueia local**, não substitui step-up
  server-side; fallback via Email OTP always-on.
- [ ] Refresh/chaves em **Keychain/Keystore** (Secure Enclave/StrongBox); **nada** em store em
  claro; token nunca em log/crash/analytics.
- [ ] **Logout irreversível** (revoga refresh+família no IdP, desassocia push); device é sessão
  revogável remotamente; push token rotacionado no logout/troca de usuário.
- [ ] **Authz sempre no servidor** (deny-default, token fino, ReBAC multi-tenant); esconder botão ≠
  autorizar.
- [ ] Jailbreak/root alimenta o **risk engine**; testes de abuso de fluxo no IdP (schematize-pentest).
- [ ] **Contas não-humanas** (seed/persona/fixture/demo/review) **só** em `test.<domain>` de rota
  nula ou TLD reservado — **nenhum** e-mail de pessoa real; o gate local trava caixa real.
- [ ] **E2E de Email OTP lê o código no SINK** (API HTTP), nunca em caixa real; guard
  deny-by-default no provider + **cap por execução** provados por teste que vê o vermelho (§8).
