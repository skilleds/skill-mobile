---
description: Gera o handoff de contexto (context.md + checklist.md) no archive, SEM compactar
---

Gere o handoff do trabalho de mobile **sem** compactar — pra fim de sessão ou troca de tarefa:

1. `<projeto>_archive/context/<YYYY-MM-DD-HH-MM-SS>-context.md` — plataforma + ADR, estado do IAM
   mobile / offline-sync / segurança / entrega, decisões, telas/casos de uso tocados, o que falta,
   onde parou.
2. `<projeto>_archive/context/<YYYY-MM-DD-HH-MM-SS>-checklist.md` — **FEITO vs EM ABERTO** (pisos
   verificados vs pendentes; itens da DoD mobile por provar).

Não rode `/compact` — só arquiva.
