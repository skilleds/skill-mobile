<!-- cross-skill: arquitetura.md, iam.md -> schematize-engineering -->
# Escolha de plataforma — nativo vs cross, por fit + ADR (não por gosto)

> A casa **não tem "a plataforma única"** de mobile — tem **um rol de opções sancionadas** e um
> **guia de fit**, exatamente como a política de linguagem de backend (`schematize-engineering`,
> `linguagens.md`). O piso — segurança, IAM, testes, ops, observabilidade, DoD, archive — é **o
> mesmo** em qualquer plataforma. A plataforma muda o **como**, nunca o **o quê**. A decisão
> vira **ADR (§27)**.

App mobile é software da casa como qualquer outro: entra no `_archive` (§28), passa pela DoD
(§35), tem índice/MAPA (§39), IAM por desenho (`iam-mobile.md`). O que este reference define é a
**primeira decisão estrutural** — nativo ou cross — e como registrá-la sem virar religião.

## 1. O rol de plataformas sancionadas

| Abordagem | Stack | Sufixo de repo | Quando encaixa |
|---|---|---|---|
| **Nativo iOS** | Swift + SwiftUI | `_ios` | app iOS-first, uso pesado de APIs de plataforma (widgets, Live Activities, HealthKit, ARKit), latência/animação críticas |
| **Nativo Android** | Kotlin + Compose | `_android` | app Android-first, integração profunda com SO, background/serviços de sistema |
| **Cross — Kotlin Multiplatform** | KMP (+ Compose Multiplatform) | `_kmp` | compartilhar **lógica/domínio** entre plataformas mantendo UI nativa (ou Compose) — default cross quando a equipe é Kotlin |
| **Cross — Flutter** | Dart + Flutter | `_flutter` | UI consistente pixel-a-pixel entre plataformas, iteração rápida de produto, time único |
| **Cross — React Native** | RN + TypeScript, **New Architecture** | `_rn` | reuso de time/ecossistema web (React), fit com `schematize-web`, OTA de JS bundle |

> **PWA / web app** não é "app mobile nativo": é frontend, governado por `schematize-web`
> (responsivo, mobile utilizável, CWV). Vira app instalável quando há requisito real de loja,
> push nativo, offline profundo ou API de plataforma — aí entra este rol.

> **React Native: a New Architecture não é opcional.** ✔ Verificado em 2026-08-21 — ela é o padrão
> desde a **0.76**, e a antiga (Bridge) está em caminho de remoção. Isso muda três coisas que
> aparecem no dia a dia: **JSI/TurboModules** substituem a ponte assíncrona serializada em JSON
> (módulo nativo antigo precisa de *interop layer* ou de porte), **Fabric** é o renderer, e o
> **modo síncrono/concurrent do React** passa a valer. Consequências práticas para a decisão de fit:
> **biblioteca sem suporte à New Architecture é dívida com prazo** (verifique **antes** de adotar),
> a migração de um app existente é **projeto com ADR**, não um bump de versão, e comparar RN "pelo
> que ele era" é comparar com um produto que não existe mais.

## 2. Guia de fit — a decisão vira ADR

Escolha por **encaixe com o problema**, não por preferência do time do dia. Perguntas que o ADR
tem de responder:

- **Superfície de plataforma:** o app depende de APIs que só existem nativas e frescas no dia do
  lançamento do SO (widgets, App Clips/Instant Apps, Live Activities, CarPlay/Android Auto,
  HealthKit/Health Connect, NFC, ARKit/ARCore)? Quanto mais na ponta, mais **nativo** paga.
- **Uma base ou duas?** Time pequeno + paridade de features + orçamento apertado → **cross**
  reduz custo de manter duas bases. Time por plataforma + requisitos divergentes → nativo.
- **Origem do time:** time Kotlin → **KMP**; time React/web (fit `schematize-web`) → **RN**;
  time buscando UI única e rápida → **Flutter**.
- **Performance/gráficos:** jogo, render pesado, animação 120fps, câmera/ML on-device intenso →
  nativo (ou Flutter com cuidado). CRUD/produto/conteúdo → cross serve bem.
- **Longevidade e risco de runtime:** cross adiciona um runtime/ponte entre você e o SO — pesa o
  risco de a ponte atrasar em novas versões do SO. Custo de errar alto → nativo.

> Regra de fit: um app iOS-first com Live Activities pede **Swift**; um app de produto
> multiplataforma com time Kotlin pede **KMP**; um app de conteúdo com time React pede **RN**; um
> app com UI única e iteração rápida pede **Flutter**. Se dois encaixam, escolha o **menor custo
> de manutenção para este time** e registre o porquê no ADR. Sem ADR, a escolha é dívida.

## 3. Fora do rol (exige ADR de exceção)

- **Cordova/Ionic/WebView-wrapper** para app novo com requisito nativo real → **vetado sem ADR de
  exceção**. WebView tem lugar (conteúdo remoto dentro do app), não como a arquitetura inteira de
  um app que precisa de offline/biometria/push nativo.
- **Nova plataforma/runtime fora do rol** (ex.: framework exótico) exige ADR de exceção aprovado —
  não se adota por hype.

## 4. Arquitetura interna (independe da plataforma)

Escolhida a plataforma, a arquitetura segue os pisos da engenharia (`arquitetura.md`):

- **Camadas explícitas:** UI (view/composable) → apresentação (view-model/state) → domínio
  (casos de uso, regras) → dados (repositórios, fontes local/remota). A **regra de dependência**
  aponta pra dentro: domínio não conhece UI nem SDK de rede.
- **Domínio sem framework:** a regra de negócio não importa `UIKit`/`android.*`/`Flutter` — é
  testável sem device/emulador. Em cross (KMP), o domínio é o **shared module**; a UI é o que
  varia.
- **Fronteira cliente/servidor explícita (§ segurança):** o app é **território hostil** — decisão
  de autorização, preço, regra sensível moram no **servidor**. O app é conveniência de UX, nunca
  a fonte de verdade nem o guardião do segredo (`iam-mobile.md`, `seguranca-mobile.md`).
- **Um arquivo, uma unidade lógica; índice/MAPA (§39):** o app entra no índice global igual a
  qualquer serviço — telas, casos de uso e endpoints consumidos mapeados.

## 4.1 i18n e localização — o retrofit é mais caro aqui do que na web

O piso da casa é **i18n-ready por padrão** (`schematize-web`), e no mobile ele vale **mais**, não
menos: no web você troca o texto e faz deploy; no app, a string errada **está instalada**, e a
correção espera a próxima submissão e o rollout.

**MUST**
- **Nenhuma string literal na UI.** Tudo vem do catálogo de recursos (`Localizable.strings`/String
  Catalog no iOS, `strings.xml` no Android, ARB no Flutter) — inclusive as de erro, que são as que
  mais aparecem em produção e as que mais ficam em inglês.
- **Plural e gênero pelo mecanismo da plataforma** (`stringsdict`/`plurals`/ICU), nunca por
  `if (n == 1)`: a regra de plural do polonês, do russo e do árabe **não é binária**, e o `if`
  fabrica texto errado sem erro nenhum.
- **Nada de concatenar frase** — use **placeholder posicional** (`%1$s comprou %2$s`), porque a
  ordem das palavras muda entre idiomas e a concatenação trava a ordem do português.
- **Formato vem do locale, não do código:** data, hora, número, moeda e nome próprio pelo
  formatador do SO. Data escrita à mão é o bug que só aparece no mês 13.
- **O locale é do usuário, não do dispositivo inteiro:** iOS e Android permitem idioma **por app**;
  respeite a escolha e ofereça-a se o produto tiver público em mais de um idioma.
- **Layout que estica:** alemão cresce ~35% e o árabe inverte a direção. **Teste com pseudo-locale**
  (texto alongado + acentuado) e com **RTL**, no fontScale máximo — é o que revela o botão cortado
  antes do usuário.
- **Conteúdo dinâmico do servidor também é traduzível** (ou o app fica meio traduzido): o idioma vai
  no header da request, e o backend responde no idioma pedido.

**Por que "depois" custa caro:** extrair string de um app pronto é mexer em **toda** tela, e o
retrofit não tem gate que o force — enquanto a tela nova em inglês passa despercebida. Nascer
i18n-ready custa uma tarde; migrar custa uma release inteira e ainda deixa resto.

## 5. Backend do app é serviço da casa

O app quase nunca vive sozinho: fala com um **backend do rol sancionado** (Go/Rust/Elixir/C#/Zig/
Ruby), com **IAM como app separada** em `auth.<domain>` (`iam.md`). O contrato de API (BFF/gateway)
é versionado e testado; o app **delega** authz e segredo ao servidor. Mobile não é ilha: é o
cliente de uma arquitetura que já tem os pisos da casa.
