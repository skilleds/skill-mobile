# Offline-first & sincronização — a rede é intermitente por padrão

> No desktop a rede é quase sempre presumida; no **mobile ela falha o tempo todo** — metrô,
> elevador, roaming, avião, sinal fraco. App da casa é **offline-first por desenho**: usável sem
> rede, e a sincronização é um **problema de dados distribuídos** (conflito, fila, reconciliação),
> não um "salva quando dá". Este é o piso; o servidor continua sendo a **fonte de verdade**.

Offline-first não é "cachear o último request". É tratar o dispositivo como uma **réplica local**
que aceita leitura e escrita sem rede, e reconcilia com o servidor quando a rede volta — sem
perder escrita do usuário e sem corromper o estado.

## 1. Princípios

- **A UI lê do local, sempre.** A tela renderiza do banco/local store (SQLite, Room, Core Data,
  SQLDelight, GRDB), nunca direto do request. ✔ **2026-08-21: `Realm` saiu da lista** — o Atlas
  Device SDK foi **depreciado em set/2024 e chegou ao EOL em set/2025**. Base local é decisão de
  anos: escolher um store em EOL custa uma migração de dados no dispositivo do usuário, que é a
  migração mais cara que existe (sem janela, sem rollback e sem acesso à máquina). Alternativas
  vivas com sync: **PowerSync**, **Turso/libSQL embedded replica**, ou sync próprio sobre SQLite
  com a outbox desta seção. A rede **alimenta** o local; a UI **observa** o
  local. Rede caindo no meio não trava a tela.
- **Escrita é otimista + fila durável.** Ação do usuário grava local na hora (UI responde já) e
  enfileira uma **mutação durável** pra enviar. A fila sobrevive a fechar o app, matar o processo,
  reiniciar o device (persistida em disco, não em memória).
- **O servidor é a fonte de verdade.** O local é réplica; em conflito, a política de resolução
  decide, mas a **autoridade** (e a authz — `iam-mobile.md`) é do servidor. O cliente nunca é o
  juiz de saldo, estoque, preço ou permissão.
- **Idempotência ponta a ponta.** Toda mutação carrega uma **chave de idempotência** (ULID gerado
  no device) — reenvio após timeout não duplica. O servidor deduplica por essa chave.

## 2. A fila de mutações (outbox)

O padrão é uma **outbox** local: cada escrita do usuário vira um registro persistido
`{op_id (ULID), tipo, payload, base_version, criado_em, tentativas, estado}`.

- **Envio ordenado e em lote** quando a rede volta; respeita dependências (não envia "editar item"
  antes de "criar item").
- **Retry com backoff exponencial + jitter**; teto de tentativas → move pra **dead-letter** local
  e sinaliza ao usuário (não fica reenviando pra sempre queimando bateria/dados).
- **Estados explícitos por item:** `pendente → enviando → confirmado | conflito | falho`. A UI
  pode mostrar "sincronizando…"/"salvo"/"falhou, toque pra tentar".
- **Nada de segredo/PII em claro na fila.** A outbox mora no armazenamento do app; dado sensível
  em repouso é cifrado (`seguranca-mobile.md`, secure storage).

## 3. Sincronização — pull, push e delta

- **Delta sync, não full-refresh.** Sincronize por **cursor/timestamp/versão** (`updated_since`,
  change-token) — baixe só o que mudou. Full-refresh a cada abertura queima bateria, dados e
  bateria do servidor.
- **Paginação e limites:** sync incremental paginado; nunca "baixa tudo" num device com pouca
  memória/armazenamento.
- **Tombstones para deleção:** deletar é um evento sincronizável (marca `deleted_at`), senão o
  item apagado no servidor "ressuscita" no device. Soft-delete no protocolo de sync.
- **Relógio não confiável:** o relógio do device mente (fuso, ajuste manual). Use **versão do
  servidor**/vetor/HLC pra ordenar, não o wall-clock do cliente como verdade.

### 3.1 O sync-token é um CONTRATO, não um gesto

"Sincronize por cursor" é meia frase. O token de sincronização precisa ter estas propriedades
escritas — e é o servidor quem as garante:

- **Opaco.** O cliente **não interpreta** o token (não é timestamp legível, não é id de linha). No
  dia em que o servidor mudar a estratégia (de `updated_at` para LSN, para versão de tabela), o
  cliente que "sabia" o que o token significava quebra — e ele está **instalado**, fora do seu
  alcance.
- **Monotônico.** Aplicar as páginas na ordem em que vieram converge; e reenviar o mesmo token
  devolve o mesmo ponto de partida.
- **Expirável, com `410 Gone` ⇒ full resync.** Token velho demais (retenção do log de mudanças
  estourada, migração no servidor) **não pode devolver dado parcial**: responde `410`, e o cliente
  faz **ressincronização completa** — feia, mas correta. Devolver 200 com delta incompleto é como
  o cliente fica com um estado que nunca converge, e ninguém descobre porque não há erro.
- **Com política de retenção declarada:** "tokens valem N dias". Sem isso, o app que ficou 6 meses
  na gaveta pede um delta que o servidor não sabe mais calcular.
- **Idempotência dos dois lados:** o push carrega chave de idempotência por mutação; o pull pode ser
  repetido sem duplicar.

**Tombstone tem ciclo de vida.** Deleção só chega ao cliente offline se ficar registrada — e
registro que nunca some vira tabela infinita. A regra: **TTL do tombstone ≥ janela do sync-token**,
e o GC apaga o que passou dos dois. Se o cliente volta depois do TTL, ele cai no `410` do item
anterior (que é justamente por que os dois números andam juntos).

### 3.2 Migração do schema local e da outbox — não há rollback no device

O banco local **evolui junto com o app**, e aqui **não existe `down migration`**: o binário já está
instalado, e a versão anterior pode voltar (o usuário reinstala, ou o rollout é revertido).

- **Migração é para frente, e é testada a partir da versão publicada** — não do zero
  (`testes-mobile.md` §3: teste que cria o banco novo **não** testa migração).
- **A outbox migra junto.** É o caso mais esquecido e o mais caro: se o formato da mutação enfileirada
  mudou, o app novo abre uma fila **escrita pelo app velho**. Ou você versiona **cada item** da fila
  (com o `schema_version` dentro) e sabe ler o formato antigo, ou você **drena antes de migrar** — e
  drenar exige rede, que é exatamente o que pode não haver.
- **Nunca descarte a fila em silêncio.** Se um item não puder ser migrado, ele vai para uma
  **quarentena visível** (com log e, se afetar o usuário, aviso) — mutação que some sem rastro é
  "salvou" que virou mentira, o piso do §1.
- **Versão do schema gravada no banco** e **checada no boot**: app antigo abrindo banco **novo**
  (rollback de rollout) tem de **recusar com mensagem**, não tentar ler.
- **Antes de migrar, backup do arquivo local** quando o dado é insubstituível (rascunho, foto) — a
  migração que corrompe no device é irreversível.

## 4. Conflitos — a decisão tem de ser explícita

Dois lados editaram o mesmo dado offline. **Não existe default seguro universal** — a política é
uma **decisão de produto que vira ADR**:

- **Last-write-wins (LWW):** simples, mas **perde escrita**. Só para dado onde perder é aceitável
  (ex.: preferência de UI). Nunca para dinheiro, estoque, texto do usuário.
- **Merge por campo / três-vias:** reconcilia campo a campo contra a `base_version`. Bom para
  formulários/registros estruturados.
- **CRDT** (ex.: texto colaborativo, contadores): convergência sem coordenação — quando o domínio
  pede edição concorrente de verdade.
- **Resolução pelo usuário:** quando o merge automático perde intenção, **mostre o conflito** e
  deixe o usuário escolher. Nunca descarte a escrita dele em silêncio.
- **Autoridade do servidor:** operação sensível (saldo, cupom, permissão) → o cliente propõe, o
  **servidor decide** e responde com o estado canônico; conflito vira "sua ação foi rejeitada
  porque…", não um merge otimista aceito no escuro.

> Piso: **nenhuma escrita do usuário some sem ele saber.** Conflito resolvido descartando dado é
> só legítimo se a política diz explicitamente que aquele dado é descartável — e isso está no ADR.

## 5. UX de estado de rede (honesta)

- **Mostre o estado real:** offline / sincronizando / sincronizado / falha. Nunca finja "salvo"
  quando está só na fila local não confirmada.
- **Degrada, não bloqueia:** o que exige rede (pagamento, verificação, ação sensível) fica
  claramente indisponível offline com mensagem — o resto do app continua usável (mesma filosofia
  de "degrada, não bloqueia" do IAM).
- **Sem spinner infinito:** timeout + estado de erro acionável em toda operação de rede.

## 6. Testes de offline/sync (entram na DoD)

- **Testes de reconciliação:** cria conflito determinístico (edita A e B a partir da mesma base) e
  prova que a política resolve como especificado — teste que **falha** se o merge regride.
- **Idempotência:** reenvio da mesma mutação não duplica no servidor (teste de integração).
- **Corte de rede no meio:** app killado com fila pendente → reabre → fila sobrevive e drena.
- **Relógio adverso:** device com relógio adiantado/atrasado não corrompe a ordenação.
- **Airplane-mode no CI/manual:** roteiro de QA (`/mobile-offline`) que exercita o app 100%
  offline e valida que nada trava nem perde dado.
