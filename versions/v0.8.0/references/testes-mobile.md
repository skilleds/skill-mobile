<!-- cross-skill: piramide.md, flaky.md -> schematize-qa -->

# Testes no app — o que muda no mobile (e o que não muda)

> **PONTEIRO, não cópia.** A disciplina de teste é da **`schematize-qa`**: pirâmide, teste de
> comportamento (não de implementação), cobertura útil, o "verde de verdade", flaky, e o fluxo
> plan-first com os gates de CI. **Leia lá primeiro.** Aqui fica só o que o **dispositivo** muda —
> e ele muda bastante, porque o mobile tem quatro coisas que o servidor não tem: **o app é
> instalado** (existe estado de ontem), **o SO interrompe** (mata, congela, nega permissão), **o
> parque é heterogêneo** (versão de SO × tela × API level) e **o release é lento** (o bug vai para a
> loja e demora dias para sair de lá).
>
> A skill promete *"o mesmo piso, incluindo **testes**"* e entregava **9 linhas** dentro de
> `offline-sync.md` §6 — achado da vistoria de 2026-08-21. Estas linhas cobrem o buraco; a **base
> continua sendo a `schematize-qa`**, e onde este arquivo divergir dela, **ela manda**.

## 1. A pirâmide, no app

A forma é a mesma da base (muita unidade, alguma integração, pouca ponta-a-ponta). O que muda é
**onde ficam as fronteiras**:

| Camada | No app | Regra |
|---|---|---|
| **Unidade** | lógica de domínio, view-model/presenter, reducers, mapeamento de DTO | roda na **JVM/simulador sem device**, em milissegundos. Nada de `Context`/`UIApplication` aqui — se precisa, a fronteira está errada |
| **Integração** | banco local (migração, query), outbox, cliente HTTP contra servidor **falso** (não mock de método), repositório | usa device/emulador, mas **sem rede real e sem backend real** |
| **UI/instrumentado** | fluxo com toque, navegação, estado visível | caro e lento: reserve para os **caminhos que o negócio perde se quebrarem** |
| **Ponta-a-ponta** | app real + backend de teste | poucos, e **nunca** contra produção (`entrega-lojas.md` §7) |

**O teste que passa só no seu Mac não é teste.** Suíte que depende do simulador aberto, do device
pareado ou do cache quente do build é a fonte nº 1 de flaky no mobile — trate exatamente como a
`schematize-qa` trata flaky: quarentena com dono e prazo, nunca `@Ignore` silencioso.

## 2. Matriz de dispositivos — escolhida, não sorteada

Testar em "um Android e um iPhone" é testar no seu bolso. A matriz é **decisão escrita**, derivada
de dado:

- **Piso e teto de SO:** a versão **mínima suportada** (a que mais quebra) e a **mais nova** (a que
  muda comportamento sem avisar). As duas rodam por commit, local, sempre. As do meio, por amostragem.
- **Do parque real:** as 3–5 combinações mais frequentes **dos seus usuários** (analytics), não as
  mais vendidas do mercado.
- **Os extremos que quebram layout:** menor tela suportada, maior fonte de acessibilidade
  (Dynamic Type / `fontScale`), tema escuro, RTL se o app tiver.
- **Um device físico lento e real** para o smoke de release — emulador não reproduz térmica,
  bateria, rede móvel nem armazenamento cheio.

Registre a matriz no repo com a **data e a fonte do número**. Matriz sem data envelhece calada, e
API level velho some do parque sem ninguém notar.

## 3. Os testes que só existem no mobile

Estes são a razão deste capítulo. Nenhum deles tem equivalente no servidor:

- **Permissão negada — e negada para sempre.** Câmera, localização, notificação, arquivos: teste
  os **três** estados (concedida, negada, negada permanentemente/"não perguntar mais") e prove que
  o app **continua usável** e explica o que se perde. App que trava ou entra em loop de pedido na
  recusa é bug de release, não de UX.
- **Deep link e universal link.** Cada rota profunda tem teste: **app fechado**, **app em
  background**, **usuário deslogado** (o link sobrevive ao login?), **link inválido/adulterado** (não
  navega para tela privilegiada, não confia em parâmetro). O link é **entrada não confiável** —
  mesma régua de input hostil da `schematize-pentest`.
- **Migração do banco local.** É o teste mais esquecido e o mais caro de errar: **não existe
  rollback no device do usuário**. Para cada versão do schema, um teste que abre um banco **da versão
  anterior com dado real de fixture** e prova que migra sem perder linha. Teste que cria o banco do
  zero **não** testa migração — é a condição vacuamente verdadeira do mobile.
- **Upgrade de app com estado.** Instala a versão N-1, gera estado (sessão, fila do outbox,
  preferências), atualiza para N, abre: sessão sobrevive, fila drena, nada de tela em branco.
- **Processo morto pelo SO.** Android mata em background; iOS suspende e descarta. Teste
  restauração de estado (`SavedStateHandle` / `NSUserActivity`+state restoration) com o app morto no
  meio de um fluxo — e não confunda "voltou" com "recomeçou do zero".
- **Interrupção real:** ligação/alarme no meio do fluxo, rotação, split-screen, teclado cobrindo o
  campo, foreground/background durante upload.
- **Rede ruim, não rede ausente.** Offline é o caso fácil. O difícil é **lento, instável e mentiroso**
  (captive portal, DNS que resolve e não conecta, 3G com 40% de perda): timeout, retry com backoff e
  estado de erro acionável — sem spinner infinito (`offline-sync.md` §5).
- **Relógio, fuso e locale adversos:** device com relógio adiantado, mudança de fuso em viagem,
  locale que troca separador decimal e formato de data. Ordenação e parsing quebram aqui.
- **Armazenamento cheio e memória baixa:** gravação que falha por disco cheio precisa falhar
  **visivelmente**, nunca perder a fila em silêncio.

## 4. Acessibilidade não é capítulo à parte

Cada tela do caminho crítico tem teste de a11y automatizado (labels, alvo de toque mínimo,
contraste, foco, navegação por leitor de tela) — a base é a `schematize-qa`. No mobile, some a isto
o **fontScale máximo** e o **modo escuro**: são as duas configurações que mais quebram layout na
mão do usuário real, e as duas mais fáceis de esquecer no simulador default.

## 5. Segurança e IAM entram na suíte

Teste, não confie: chave sai do **Keychain/Keystore** e nunca de `SharedPreferences`/`UserDefaults`;
**logout é irreversível** (token revogado no servidor, não só apagado do device — `iam-mobile.md`);
biometria desbloqueia o **local** e não substitui step-up no servidor; build de não-prd **não fala
com prd** (`entrega-lojas.md` §7, e o gate `scripts/check-external-effects.sh`); nenhum segredo no
bundle (o app roda na máquina do adversário). O lado ofensivo é `/pentest-*`; aqui é o construtivo.

## 6. Push tem suíte própria

Registro, rotação e limpeza de token; permissão negada; payload hostil. Os casos estão em
`performance.md` §4.1 — e são teste de verdade, com servidor falso, porque **push não se testa
mandando push de verdade** (`efeitos-externos`).

## 7. Onde roda, e o que sai da DoD

- **Todo commit (gate LOCAL):** unidade + integração no piso e no teto de SO, simulador local. Rápido, senão vira opcional.
- **Tag `hml-*`/`v*` ou pedido (CI remoto, piso 27):** UI nos caminhos críticos + a matriz completa/device farm + a11y.
- **Antes de subir para a loja:** smoke em **device físico**, teste de **upgrade** a partir da
  versão publicada, e o gate de crash-free (`entrega-lojas.md`).
- **Cobertura faltante não vira "sem bug"** — é o mesmo piso da `schematize-qa` e da
  `schematize-pentest`. O que não foi testado entra no relatório como **não testado**, com nome.

**Não fecha a DoD sem:** migração testada a partir da versão anterior · permissão negada nos três
estados · deep link com app fechado e usuário deslogado · restauração após processo morto · matriz
de dispositivos escrita **e datada** · suíte de push (§6) · nenhum teste em quarentena sem dono e
prazo.
