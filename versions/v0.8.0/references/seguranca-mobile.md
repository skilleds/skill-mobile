<!-- cross-skill: cadeia-suprimentos.md, seguranca.md -> schematize-engineering -->
# Segurança mobile — o dispositivo é território hostil

> O piso de segurança da casa (`seguranca.md`) vale inteiro no mobile; este reference diz o que o
> **cliente hostil** acrescenta. Premissa: **o app roda numa máquina do adversário** — bundle
> extraível, tráfego interceptável, device com root/jailbreak, debugger acoplável. Toda segurança
> que **depende do cliente** é enfeite; a que vale mora no **servidor**. O app faz *defesa em
> profundidade*, não *segurança por obscuridade*.

## 1. Nunca segredo no bundle — o piso inegociável

- **Segredo NÃO existe no app.** API key privada, `client_secret`, chave de assinatura, token de
  serviço, credencial de banco — **nada** disso vai no bundle, no código, em `Info.plist`/
  `strings.xml`, em `BuildConfig`, em `.env` compilado, ou em variável "pública" (mesma regra do
  `NEXT_PUBLIC_`/`VITE_` do `schematize-web`). Extrair o `.ipa`/`.apk` e ler as strings é trivial.
- **O que o app pode ter:** identificadores públicos (client_id OIDC, chave pública/JWKS, chave de
  API *pública* com escopo restrito e rate-limit server-side). Se vazar e causar dano, **não era**
  público — vai pro servidor atrás de um BFF.
- **Segredo que precisa existir → fica no backend**, e o app chama um endpoint autenticado. Terceiro
  que exige segredo do cliente → **proxy pelo servidor** (o app fala com o seu backend, o backend
  fala com o terceiro guardando o segredo).
- **Scan de segredo no CI:** gitleaks/trufflehog no repo e no artefato buildado. Segredo achado no
  rastro → **rotação** + remoção, não "depois a gente troca".

## 2. Transporte — TLS + certificate pinning consciente

- **TLS sempre**, HSTS no servidor; **App Transport Security (iOS)** e **Network Security Config
  (Android)** sem exceções de cleartext em produção.
- **Certificate/public-key pinning** para o backend da casa: fixe a **chave pública (SPKI)**, não o
  certificado inteiro (sobrevive à renovação). Pinning aumenta o custo de MITM — mas:
  - **Pin com backup + plano de rotação:** pin único sem backup = app quebra quando a chave gira.
    Fixe ≥2 (atual + próxima) e tenha caminho de atualização (config remota assinada / release).
  - **Pinning é defesa, não muleta:** não substitui validar authz no servidor; complica intercepção
    de tráfego por analista casual/MITM, não impede um device rooteado com framework de hooking.

## 3. Root/jailbreak awareness — sinaliza, não confia

- **Detecte** root/jailbreak, emulador, debugger acoplado, hooking (Frida/Xposed) e **integridade
  de app** (Play Integrity API / App Attest + DeviceCheck) — mas trate como **sinal**, não como
  garantia: toda detecção client-side é burlável.
- **Uso correto do sinal:** alimenta o **risk engine do IdP** (`iam-mobile.md` §7) → step-up,
  negação deceptiva, alerta. Pode **degradar** funções de alto risco (dinheiro) num device
  comprometido. **Não** vire um bloqueio total ingênuo ("device rooteado = app não abre") sem ADR —
  usuários de bem usam root; a decisão é de produto/risco, datada.
- **A verdade é do servidor:** attestation (App Attest/Play Integrity) é verificada **no servidor**,
  que decide; o app não é o juiz da própria integridade.

## 4. Ofuscação sensata — custo, não impossibilidade

- **Ofuscação eleva o custo de engenharia reversa; não protege segredo** (segredo continua fora do
  bundle, §1). Use **R8/ProGuard (Android)** com shrink+obfuscate; no iOS, símbolos strip + evitar
  strings sensíveis em claro.
- **Não ofusque em vez de arquitetar:** ofuscar um segredo embutido continua sendo segredo embutido
  — só mais lento de achar. Ofuscação é a **última** camada, depois de tirar o que não devia estar
  lá.
- **Anti-tamper proporcional:** checagem de assinatura do próprio app / anti-debug faz sentido em
  app de alto valor (fintech), é overkill em app de conteúdo. Proporcional ao risco, no ADR.

## 5. Dados em repouso e superfície local

- **Cifra em repouso** para dado sensível/PII e para a **outbox de sync** (`offline-sync.md`):
  chave no **Keychain/Keystore** (Secure Enclave/StrongBox), nunca hardcoded. Bancos locais
  sensíveis → SQLCipher/DB cifrado.
- **Nada sensível em:** logs, `UserDefaults`/`SharedPreferences` em claro, cache de screenshots do
  app switcher (oculte a tela sensível no background), clipboard sem expiração, pasteboard
  compartilhado.
- **Backups do SO:** exclua segredo dos backups iCloud/Android Auto Backup (flags de exclusão);
  senão o segredo vaza pro backup em nuvem.
- **Deep links e IPC:** valide **toda** entrada de deep link/intent/URL scheme como entrada hostil
  (é superfície de ataque externa); nunca execute ação sensível só porque veio de um link.
  Intents/activities/serviços não exportados por default; exporte só o necessário e valide o caller.
- **WebViews:** se houver WebView, `JavaScriptEnabled` só quando preciso, sem `addJavascriptInterface`
  exposto a conteúdo remoto, sem carregar HTML não confiável; conteúdo remoto ≠ contexto do app.

## 6. Terceiros e cadeia de suprimentos

- **SDKs de terceiro são superfície e risco de privacidade:** todo SDK (analytics, ads, crash, A/B)
  vê o que você deixa ver. Minimize, audite permissões, e **nunca** deixe SDK ver token/PII sem
  necessidade. SDK abandonado/duvidoso é dívida de segurança.
- **Cadeia de suprimentos (`cadeia-suprimentos.md`):** pin de versões, SBOM, `npm/pod/gradle audit`,
  build reproduzível; dependência de mobile é código de terceiro no device do usuário.
- **Permissões do app (privacy):** peça o **mínimo** e **just-in-time** com justificativa; declare
  corretamente no App Privacy (Apple) / Data safety (Google). Permissão pedida a mais é rejeição de
  loja e desconfiança do usuário.

## 7. O que a segurança mobile NÃO substitui

O servidor continua dono da verdade: **authz (`iam-mobile.md`), validação de input, rate-limit,
regra de negócio e preço**. Pinning, attestation e ofuscação **elevam o custo** do atacante — não
transferem a decisão de segurança pro cliente. Um app "muito protegido" com endpoint sem authz é
inseguro. A ordem é: **servidor correto primeiro**, defesa em profundidade no cliente depois.

## Telemetria e crash — por que mobile e desktop divergem DE PROPÓSITO

A `schematize-desktop` manda **nada por padrão**: sem telemetria, crash só com opt-in. Aqui, crash
reporting é **obrigatório** e analytics é **opt-out**. Não é contradição — é a mesma regra aplicada
a duas realidades diferentes, e a diferença precisa estar escrita para ninguém "harmonizar" as
duas para o lado errado:

| | Mobile | Desktop |
|---|---|---|
| **Crash** | **obrigatório** (com símbolos) | **opt-in** |
| **Analytics de uso** | **opt-out** (avisado na privacy label) | **não existe** por padrão |
| **Por quê** | o app roda em **milhares de combinações de device/SO** que você não tem; sem crash agregado, o bug de um device específico é invisível — e o **rollout escalonado depende do crash-free rate como gate** | o app roda na **máquina do usuário**, com dados dele; o SO já dá diagnóstico local, e a expectativa cultural de privacidade em desktop é outra |
| **O que NÃO muda** | telemetria **sem PII**, agregada, com finalidade declarada; SDK de terceiro é superfície auditada; a privacy label diz a verdade | idem |

> **Update pós-instalação:** o piso é o **mesmo** dos dois lados — **assinado, verificado e
> reversível**. A `schematize-desktop` detalha (assinatura, pin, rollback) porque no desktop **você
> é a loja**; no mobile a loja faz parte disso por você, **exceto no OTA de bundle JS**, que é
> exatamente o ponto em que o mobile volta a precisar do piso inteiro (`entrega-lojas.md`).
