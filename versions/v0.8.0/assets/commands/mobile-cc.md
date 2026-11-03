---
description: Context Compact — gera handoff (context.md + checklist.md) no <projeto>_archive e compacta
---

Antes de compactar, **arquive o handoff** (não perca o estado do trabalho de mobile):

1. `<projeto>_archive/context/<YYYY-MM-DD-HH-MM-SS>-context.md` — estado: plataforma escolhida
   (e ADR), o que já foi feito no IAM mobile / offline-sync / segurança / entrega, decisões
   pendentes, telas/casos de uso tocados, onde parou.
2. `<projeto>_archive/context/<YYYY-MM-DD-HH-MM-SS>-checklist.md` — **FEITO vs EM ABERTO**
   (pisos verificados vs pendentes: segredo fora do bundle? authz no servidor? secure storage?
   outbox durável? rollout com gate?).
3. Só então rode `/compact` (foco na tarefa corrente).
