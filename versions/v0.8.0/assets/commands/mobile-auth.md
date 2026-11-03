---
description: schematize-mobile — força/audita o IAM mobile casado com o iam.md (OIDC/PKCE ao auth.<domain>, passkeys+biometria, secure storage, logout irreversível, sem segredo no bundle, authz no servidor)
argument-hint: "[dir do app, ex: <projeto>_ios | <projeto>_android | <projeto>_kmp]"
---
<!-- cross-skill: iam.md -> schematize-engineering -->
<!-- cross-skill: protocolos.md, fatores.md, sessao.md -> schematize-iam -->

Force/audite o **IAM mobile** deste app (`references/iam-mobile.md`), **casado com o `iam.md`** da
`schematize-engineering`. O app é só **mais um cliente do IdP da casa** — ele **não** implementa
auth. Se o app não tem IAM ainda, **scaffolde** o fluxo correto; se tem, **audite** contra os pisos.

> O broker (fluxo, tokens, fatores, sessão) é da `schematize-iam`: `schematize-iam → references/protocolos.md`, `schematize-iam → references/fatores.md`, `schematize-iam → references/sessao.md`; em auditoria rode também `schematize-iam → scripts/check-iam.sh`. Aqui só o lado do cliente nativo.

## 1. Delegação ao IdP (não reinventar auth)
- O app é **public client** e delega ao `auth.<domain>` por **OIDC/OAuth 2.1 + PKCE** — **VETADO**
  login próprio, hash de senha no app, ROPC ou implicit flow.
- **NUNCA `client_secret` no bundle.** Confira `Info.plist`/`strings.xml`/`BuildConfig`/env
  compilado — segredo achado → **rotação** + remoção.
- Retorno por **Universal Links (iOS) / App Links (Android) verificados** (não custom scheme cru);
  login no **navegador do sistema** (ASWebAuthenticationSession / Custom Tabs), **nunca WebView**.
- `state` + PKCE validados no retorno.

## 2. Fatores — passkeys+biometria no núcleo
- **Passkeys de plataforma** (AuthenticationServices / Credential Manager) como fator forte.
- **Biometria (Face ID/Touch ID/BiometricPrompt) desbloqueia LOCAL** a chave/refresh — **não**
  substitui **step-up server-side** (AAL alto) pra op sensível. Fallback via **Email OTP always-on**
  do IdP (`iam.md`). Biometria falsa/ausente ≠ bypass.

## 3. Tokens e sessão
- Refresh/chaves em **Keychain (iOS) / Keystore + EncryptedSharedPreferences (Android)** (Secure
  Enclave/StrongBox). **Nada** em `UserDefaults`/`SharedPreferences` em claro, arquivo, log,
  crash report ou analytics. Access token curto + **refresh rotativo com detecção de reuso**.
- **Logout irreversível:** revoga o refresh (**e a família**) no IdP, apaga a sessão server-side e
  **desassocia o push token** do device. Replay do token guardado não reativa nada.
- Device é **sessão de 1ª classe** revogável remotamente; push token rotacionado no logout/troca de
  usuário.

## 4. Authz — sempre no servidor
- **Deny-by-default no servidor**; o app **não** é PDP. Esconder botão é **UX**, não autorização —
  todo endpoint valida a permissão no PEP (ReBAC, `iam.md` §5). **Token fino** (sub/tenant/AAL/
  sessão, sem lista de permissões). Multi-tenant verificado a cada request.

## 5. Risco e saída
- Jailbreak/root + attestation (`seguranca-mobile.md`) alimentam o **risk engine** do IdP.
- Rode o **checklist mobile** de `iam-mobile.md` e reporte cada item como **FEITO com prova** ou
  **EM ABERTO**. Vazamento (segredo no bundle, token em store inseguro, authz no cliente, WebView de
  login, biometria autorizando sozinha) **trava** — é dívida, não "depois". Testes de abuso de fluxo
  na `schematize-pentest`.
