# schematize-mobile

> **Engenharia de apps mobile** da casa — o **mesmo piso** (segurança, IAM, testes, ops, DoD,
> archive) da `schematize-engineering`, aplicado ao **cliente hostil** que é o dispositivo, com a
> rede **offline por padrão**. Muda o "como", nunca o "o quê": nada de afrouxar segurança porque
> "é só um app".

Pacote de **skill normativa para [Claude Code](https://claude.com/claude-code)**.
Parte do catálogo **schematize skills**. Cobre iOS/Android/cross e pareia com a
`schematize-engineering` (a base: IAM/DoD/archive/índice), com o **backend do rol** que o app
consome (`schematize-go`/rust/elixir/csharp/zig/ruby) e com a `schematize-pentest` (o app é
território hostil).

## Instalar

### Pelo app schematize (recomendado)

```bash
schematize install mobile      # requer o CLI schematize instalado
```

### Última versão (a partir de um clone)

```bash
git clone https://github.com/schematizeme/skill-mobile.git
cd skill-mobile && ./install.sh            # instala no projeto atual
# ./install.sh /caminho/do/projeto          # ou aponte para outro projeto
```

Ou baixe o `.zip` da última release e descompacte em `.claude/skills/`:

```bash
curl -L -o skill-mobile.zip \
  https://github.com/schematizeme/skill-mobile/releases/latest/download/skill-mobile.zip
unzip skill-mobile.zip -d .claude/skills/
```

## O que tem dentro

- **SKILL.md** — o contrato: 10 pisos inegociáveis (o piso da casa é o mesmo; nunca segredo no
  bundle; auth delegada ao IdP no servidor; secure storage sem vazamento; passkeys+biometria no
  núcleo com biometria≠autorização; offline-first sem perder escrita; rollout gradual com gate;
  device é território hostil) + mapa de references.
- **references/** — `plataforma` (nativo vs cross por fit + ADR), `offline-sync` (outbox,
  idempotência, delta sync, conflito explícito), `iam-mobile` (OIDC/PKCE, passkeys+biometria,
  secure storage, logout irreversível), `seguranca-mobile` (pinning, root/jailbreak, ofuscação),
  `entrega-lojas` (assinatura, staged rollout, OTA, review, crash), `performance` (bateria, rede,
  push).
- **assets/commands/** — `/mobile-help`, `/mobile-load`, `/mobile-auth`, `/mobile-offline`,
  `/mobile-release`, `/mobile-claude`, `/mobile-cc`, `/mobile-handoff`.
- **assets/CLAUDE.md** — regra sempre-on do piso mobile.

## Regra de ouro

**O piso da casa é o mesmo — o mobile só muda o "como".** O dispositivo roda na máquina do
adversário e a rede cai o tempo todo: por isso segredo nunca no bundle, auth delegada ao IdP com
authz no servidor, secure storage para tokens, offline-first que não perde escrita, e release com
rollout gradual + gate. Segurança que depende do cliente é enfeite; a que vale mora no servidor.

## Relação com as outras skills

- **schematize-engineering** — a base: IAM (`iam.md`, que o `iam-mobile.md` realiza), DoD (§35),
  archive (§28), índice (§39); a escolha de plataforma espelha a política de linguagem.
- **schematize-go / rust / elixir / csharp / zig / ruby** — o backend que o app consome (authz,
  regra e segredo moram lá).
- **schematize-web** — o IdP/BFF e o fronte de auth compartilham o mesmo IAM; "segredo nunca no
  cliente" é o mesmo dos dois lados.
- **schematize-pentest** — o oráculo do cliente hostil (BOLA/BFLA, bypass de step-up, abuso de
  deep link, token em store inseguro).

Co-autoria / patrocínio: Lucassa — https://lucassa.me

MIT.
