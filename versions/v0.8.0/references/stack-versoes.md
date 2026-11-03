# Anexo volátil — requisitos de loja e ferramental mobile

> Parte da skill **schematize-mobile**. **Fonte volátil:** requisito de loja tem **data**, e
> ferramenta de mobile morre rápido. O corpo normativo diz **princípio**; o que tem prazo mora
> aqui. O lint do catálogo (regra `anexo-volatil`) reprova versão cravada fora daqui.
>
> **Verificado em: 2026-10-14** (Target API; o resto da página segue em 2026-08-21). Cadência: **revisão trimestral** — e, para os requisitos de loja,
> **antes de todo release**, porque o modo de falha deles é o app pronto não subir no dia.

## Gates de upload — os que reprovam a submissão

| Requisito | Loja | Prazo | Se faltar |
|---|---|---|---|
| **Target API level** | Google Play | **vigente desde 31/08/2026** (doc oficial do Android): novo app e atualização miram **Android 16 (API 36)**; Wear OS/Automotive API 35; TV/XR API 34. App existente precisa de **API 35+** para continuar aparecendo a novos usuários. Extensão até **01/11/2026** pedida no Play Console; app privado de organização é isento. O corte é **anual, em 31 de agosto** (o próximo, API 37, é esperado em ago/2027 <!-- reverificar -->). | upload recusado |
| **Page size de 16 KB** | Google Play (Android 15+, 64-bit) | exigido desde **01/11/2025** | upload recusado se houver `.so` desalinhado — **inclusive de SDK de terceiro** |
| **Privacy manifest** (`PrivacyInfo.xcprivacy`) | Apple | bloqueia upload **desde mai/2024** | upload recusado quando o app **ou um SDK da lista** usa *required-reason API* sem declarar, ou SDK da lista sem assinatura |

> **Ponha o 31/08 no calendário do time (o de 2026 já passou: se o `targetSdk` ainda está abaixo de 36, é bloqueio de release, não agenda).** O corte é anual e não avisa; quem descobre no dia do
> release perde o release. Trate o bump de `targetSdk` como manutenção **agendada**, com teste de
> regressão dos comportamentos que a API nova muda.

## Ferramentas que morreram

| O quê | Estado (2026-08-21) | Caminho vivo |
|---|---|---|
| **Flipper** | fora do React Native por padrão desde a **0.73** (dez/2023) | **React Native DevTools** (Hermes); Perfetto e Android Studio Profiler no Android; Instruments no iOS |
| **CodePush / App Center** | **aposentados em 31/03/2025** | **`expo-updates`/EAS Update** ou servidor de updates próprio compatível — sempre só **bundle JS**, nunca código nativo |
| **Realm / Atlas Device SDK** | **depreciado set/2024, EOL set/2025** | SQLite (Room/GRDB/SQLDelight); com sync: **PowerSync**, **Turso/libSQL embedded replica**, ou sync próprio com a outbox de `offline-sync.md` |

## Pagamento de bem digital — regra que varia por jurisdição

Não é mais "fora do IAP = rejeição" como absoluto: **DMA** (UE) e **Epic v. Apple** (EUA) abriram
steering e link-out, com regras diferentes por mercado e **mudando com o tempo**. Decida **por
mercado**, registre em **ADR**, e confira a diretriz vigente **antes de cada submissão**.

## A regra que NÃO é volátil

App é **cliente hostil**: nada de segredo no bundle, authz sempre no servidor, token em
Keychain/Keystore, login no navegador do sistema (nunca WebView), logout irreversível. Isso não
muda quando a loja muda.
