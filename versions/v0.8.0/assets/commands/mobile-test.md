---
description: schematize-mobile — planeja/audita a suíte de testes do app (pirâmide no device, matriz de dispositivos, permissão negada, deep link, migração do banco local, processo morto, push) antes de dizer que está testado
argument-hint: "[app ou fluxo]"
---

Audite ou monte a suíte de testes do app seguindo `references/testes-mobile.md`.

**A base é a `schematize-qa`** — pirâmide, teste de comportamento, cobertura útil, flaky, gates de
CI. **Leia lá primeiro.** Este comando cobre só o que o **dispositivo** muda; onde divergir, a base
manda.

## 1. Onde estão as fronteiras (§1)
Unidade roda **sem device** (view-model, domínio, mapeamento) — se precisa de `Context`/
`UIApplication`, a fronteira está errada. Integração usa emulador **sem rede real e sem backend
real** (banco local, outbox, HTTP contra servidor falso). UI/instrumentado só nos caminhos que o
negócio perde se quebrarem.

## 2. Matriz de dispositivos (§2) — escrita e **datada**
Piso e teto de SO por commit (local) sempre; as 3–5 combinações mais frequentes **do seu parque** (analytics, não
mercado); os extremos que quebram layout (menor tela, maior fontScale, tema escuro, RTL); um device
físico lento para o smoke de release. **Matriz sem data envelhece calada.**

## 3. Os casos que só existem aqui (§3) — cheque um a um
Permissão negada **nos três estados** · deep link com app fechado, em background, **deslogado** e
adulterado · **migração do banco local a partir da versão anterior com dado de fixture** (teste que
cria o banco do zero **não** testa migração — é a condição vacuamente verdadeira do mobile; e no
device do usuário **não existe rollback**) · upgrade com estado · processo morto pelo SO ·
interrupções · **rede ruim, não ausente** · relógio/fuso/locale adversos · disco cheio.

## 4. Push (§6 e `performance.md` §4.1)
Registro em toda abertura (um registro por device, nunca dois) · token trocado **substitui** ·
**logout apaga o token antes de encerrar a sessão** · troca de usuário · permissão negada ·
`targetSdk` ≥ 33 sem `POST_NOTIFICATIONS` (o caso que passa despercebido porque **não gera erro**) ·
resposta `Unregistered`/`410` apaga o registro · payload com PII reprova. Contra **servidor falso**:
push não se testa mandando push.

## 5. Segurança e IAM na suíte (§5)
Chave no Keychain/Keystore · **logout irreversível no servidor** · biometria não substitui step-up ·
build de não-prd não fala com prd (`scripts/check-external-effects.sh`) · nada de segredo no bundle.

## Gate (§7)
PR: unidade + integração no piso e no teto de SO. Release: UI crítica + matriz + a11y. Loja: smoke
em device físico + **teste de upgrade a partir da versão publicada** + crash-free.
**Cobertura faltante não vira "sem bug"**: o que não foi testado entra no relatório com nome.
