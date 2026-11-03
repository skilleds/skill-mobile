---
description: schematize-mobile — audita/planeja o offline-first & sync (UI lê do local, outbox durável, idempotência, delta sync, conflito explícito) e gera roteiro de QA 100% offline
argument-hint: "[dir do app / módulo de dados]"
---

Audite/planeje o **offline-first & sync** deste app (`references/offline-sync.md`). Premissa: a
rede **falha o tempo todo** — o app tem de ser usável sem ela, e a reconciliação é um problema de
**dados distribuídos**, não um "salva quando dá". O **servidor é a fonte de verdade**.

## 1. Leitura e escrita locais
- **A UI lê do local, sempre** (SQLite/Room/Core Data/SQLDelight/Realm) e **observa** o local; a
  rede **alimenta** o local. Rede caindo no meio não trava a tela.
- **Escrita otimista + outbox durável:** ação grava local na hora e enfileira uma **mutação
  persistida** que sobrevive a matar o app/reiniciar o device. Cada item:
  `{op_id (ULID), tipo, payload, base_version, tentativas, estado}`.
- **Idempotência ponta a ponta:** toda mutação carrega **chave de idempotência**; reenvio não
  duplica (o servidor deduplica).

## 2. Fila e sync
- Envio **ordenado, em lote, com backoff+jitter**; teto de tentativas → **dead-letter** + sinal ao
  usuário. Estados por item: `pendente → enviando → confirmado | conflito | falho`.
- **Delta sync** (cursor/versão/`updated_since`), **não** full-refresh; paginação; **tombstones**
  pra deleção (senão item apagado ressuscita). Ordene por **versão do servidor**, não pelo relógio
  do device.
- **Nada de segredo/PII em claro na outbox** — cifrado em repouso (`seguranca-mobile.md`).

## 3. Conflito — política EXPLÍCITA (vira ADR)
- Escolha e **registre** a política por tipo de dado: **LWW** (só onde perder é aceitável), **merge
  por campo/3-vias**, **CRDT** (edição concorrente real), **resolução pelo usuário**, ou
  **servidor-autoritativo** (op sensível: cliente propõe, servidor decide).
- **Piso:** **nenhuma escrita do usuário some em silêncio.** Descartar só é legítimo se a política
  diz que aquele dado é descartável — e está no ADR.

## 4. UX de rede (honesta)
- Mostre o estado real (offline / sincronizando / sincronizado / falha); nunca finja "salvo" com
  item só na fila. **Degrada, não bloqueia**: o que exige rede fica indisponível com mensagem, o
  resto segue usável. Sem spinner infinito (timeout + erro acionável).

## 5. Saída — roteiro de QA 100% offline + testes
Gere um roteiro que exercita o app **em airplane-mode** e valida:
- app usável offline (lê/escreve local); fila **sobrevive** a killar o app e **drena** ao voltar a
  rede; **idempotência** (reenvio não duplica); conflito determinístico resolve como o ADR manda;
  relógio adverso não corrompe ordenação.
Reporte cada garantia como **FEITO com teste** ou **EM ABERTO** (entra na DoD, §35).
