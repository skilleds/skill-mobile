---
description: schematize-mobile — cria ou mescla o CLAUDE.md sempre-on de mobile na raiz do repo (não sobrescreve blocos de outras skills)
---

Instale/atualize a regra **sempre-on** de engenharia de apps mobile na raiz do repositório.

1. Pegue `assets/CLAUDE.md` da skill `schematize-mobile` (projeto ou `~/.claude/skills/...`).
2. Se **não existe** `CLAUDE.md` na raiz: crie com esse conteúdo.
3. Se **já existe** (de outra skill — engineering/go/rust/web/pentest/...): **mescle** — adicione
   a seção de Engenharia de Apps Mobile **sem sobrescrever** os blocos das outras skills. Em repo
   multi-skill (ex.: monorepo app + backend), cada CLAUDE convive; o piso do mobile é aditivo.
4. Se houver customização local, salve `./CLAUDE.md.bak` e reaplique por cima.
5. Confirme a versão aplicada e destaque o **piso**: o piso da casa é o mesmo; nunca segredo no
   bundle; auth delegada ao IdP com authz no servidor; secure storage; offline-first sem perder
   escrita; release com rollout gradual + gate.
