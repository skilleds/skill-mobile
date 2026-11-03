<!-- cross-skill: observabilidade.md -> schematize-engineering -->
# Performance, bateria, rede e push — o device é limitado e o usuário sente

> No servidor a métrica é throughput; no **mobile é a experiência num aparelho fraco, com bateria
> finita, rede cara e intermitente, e um usuário que sente cada ms de travamento**. Performance
> aqui é requisito de produto (e de loja: ANR/crash derrubam ranking), não polimento opcional.
> Otimize com **perfil/medição** (mesma disciplina do `schematize-web`/CWV), nunca por achismo.

## 1. Startup e responsividade da UI

- **Cold start é a primeira impressão:** minimize trabalho no lançamento — nada de I/O de rede/disco
  pesado no `application:didFinishLaunching`/`Application.onCreate`. Inicialização preguiçosa,
  splash que dá lugar a conteúdo rápido, meça o **time-to-interactive**.
- **Nunca trabalho pesado na main/UI thread:** parsing, cripto, I/O, imagem — fora da thread de UI
  (coroutines/async, GCD, isolates). Frame budget é ~16ms (60fps) / ~8ms (120fps); estourar =
  jank. **ANR (Android)** por bloquear a main thread é rejeição/desinstalação.
- **Listas eficientes:** reciclagem (RecyclerView/LazyColumn/List/FlatList), paginação, sem
  re-render/re-layout desnecessário. Imagem dimensionada e cacheada, não bitmap gigante em
  memória.
- **Memória:** perfis de device baixo; evite leaks (listeners/observers não removidos, contexto
  retido); teste sob pressão de memória — o SO **mata** o app que abusa.

## 2. Bateria e recursos — o usuário culpa o app que drena

- **Wakelocks e background com parcimônia:** trabalho em background é caro e **restrito pelo SO**
  (Doze/App Standby no Android, limites de background no iOS). Use as APIs certas —
  **WorkManager (Android) / BGTaskScheduler (iOS)** — que agendam respeitando bateria, não loops
  próprios.
- **Coalescer e adiar:** agrupe sync/upload em janelas (device carregando + no Wi-Fi para trabalho
  pesado), não a cada evento. GPS contínuo, sensores e polling são vilões de bateria — use o menor
  nível de precisão/frequência que resolve.
- **Sem polling onde há push:** substitua "pergunta ao servidor a cada X" por push/sync sob evento
  (§4). Polling em foreground constante queima bateria e dados.

## 3. Rede — cara, lenta e intermitente

- **Assuma rede ruim por padrão** (casa com `offline-sync.md`): timeouts curtos com retry+backoff,
  operações canceláveis, degradação graciosa. Nunca UI travada esperando request.
- **Minimize bytes:** compressão (gzip/br), payload enxuto, **delta sync** em vez de full-refresh,
  paginação. Respeite **rede medida/roaming** — não baixe vídeo/asset pesado em dados móveis sem
  consentimento.
- **Cache HTTP + camada local:** ETag/Cache-Control, imagens em cache de disco com política de
  evicção. A UI lê do local; a rede reidrata (`offline-sync.md`).
- **Coalescing de requests:** deduplique chamadas idênticas em voo; batelada onde a API permite.
- **Adaptação à qualidade da rede:** em rede fraca, baixe thumbnails/qualidade menor; prefetch só
  em Wi-Fi. Detecte tipo de conexão e adapte.

## 3.1 Execução em background — é POLÍTICA do SO, não dica de bateria

Tratar background como "economize bateria" faz o time descobrir, em produção, que **o código
simplesmente não roda**. As regras são do sistema, e elas negam:

**Android**
- **App Standby Buckets** (active/working set/frequent/rare/restricted): o bucket do seu app é
  decidido pelo **uso real** e determina **quantos jobs e alarmes** você consegue por dia. App pouco
  usado cai para `rare`/`restricted` e o `WorkManager` dele roda **raramente** — o mesmo código, no
  mesmo aparelho, com comportamento diferente por usuário.
- **Doze** agrupa trabalho em janelas de manutenção com a tela apagada; **alarme exato** exige
  permissão (`SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`) e só se justifica para **alarme e
  calendário** — usá-lo para sync é abuso e reprova na revisão.
- **Foreground service com `type` declarado** (Android 14+): `dataSync`, `location`, `mediaPlayback`
  etc., com o tipo **coerente com o uso** e a permissão correspondente; e há **limite de tempo** para
  alguns tipos. FGS de `dataSync` para trabalho que não é sync é rejeição na loja.
- **Restrições do fabricante** (Xiaomi, Huawei, Samsung, Oppo) matam background **além** do AOSP.
  Se o produto depende de trabalho em segundo plano, **teste nesses aparelhos** — é onde o bug
  "só acontece com um cliente" mora.

**iOS**
- **`BGAppRefreshTask` e `BGProcessingTask` são oportunistas:** o sistema decide **se e quando**,
  com base em uso, bateria e rede. **Não há garantia de execução**, e não há "a cada 15 minutos".
- **Silent push é best-effort** e sofre *throttling* — não é canal de entrega confiável
  (`offline-sync.md`: o sync de verdade é a reconciliação, não "confio que chegou").
- **O app pode ser encerrado a qualquer momento**; trabalho longo precisa ser **retomável**, não
  "reiniciado do zero".

**MUST:** todo trabalho de background é **idempotente, retomável e observável** (você sabe quando
ele **não** rodou). E o produto **não pode depender** de execução em background para uma função
essencial — se depender, isso é decisão com ADR, e o plano B é o servidor.

## 4. Push notifications — engajamento sem abuso, e com segurança

- **Canais oficiais:** **APNs (iOS) / FCM (Android)**. O token de push é registrado no **backend da
  casa** e **atado à sessão/usuário** — rotacionado no logout/troca de usuário (`iam-mobile.md` §5),
  senão o push de um vai pro device de outro. O **registro carrega `env`/`build_id`**: push é
  **efeito externo**, e fora de `prd` vai pra **sandbox/projeto FCM de teste** — o backend de prd
  **recusa** token de build de não-prd (`entrega-lojas.md` §7).
- **Payload não é confiável nem secreto:** trate a notificação como **gatilho**, não como fonte de
  verdade — o app busca o dado real autenticado ao abrir. **Nunca** mande PII/segredo/token no
  payload de push (passa por serviço de terceiro e aparece na tela de bloqueio).
- **Permissão just-in-time e com valor:** peça permissão de notificação **no momento** em que o
  valor está claro (não na 1ª abertura, seca). Respeite a recusa; ofereça granularidade
  (categorias/canais Android).
- **Sem spam:** frequência e relevância são gate de retenção e de loja. Rate-limit no servidor,
  respeita quiet hours/preferências, opt-out fácil. Push de marketing sem consentimento = desinstala.
- **Silent/background push com limite:** úteis pra sync oportunista, mas o SO **limita** (não conte
  com entrega garantida nem alta frequência). Data push é best-effort; o sync de verdade é a
  reconciliação (`offline-sync.md`), não "confio que o push chegou".

### O ciclo de vida do token (é aqui que push vira incidente)

Push é promessa de primeira linha desta skill, e o token é a parte que quebra em silêncio: nada
falha, ninguém recebe — ou pior, **a pessoa errada recebe**.

- **Rotação, e o que a força.** O token de push **não é estável**: o SO o troca em reinstalação,
  restauração de backup, limpeza de dados, atualização do app e, no FCM, quando a instância é
  invalidada. O app **re-registra a cada abertura** (não só na primeira) e o backend **substitui**
  o registro anterior do mesmo device — nunca acumula. **Logout e troca de usuário apagam o token
  no servidor ANTES de encerrar a sessão**: token que sobrevive ao logout manda push do usuário
  antigo para o device de quem entrou depois — o vazamento cross-tenant mais fácil de causar e o
  mais constrangedor de explicar (`iam-mobile.md` §5).
- **Permissão explícita no Android também.** `POST_NOTIFICATIONS` é permissão de runtime desde o
  **Android 13 (API 33, 2022)** — não é mais "o Android entrega e pronto". Declare no manifest,
  peça **just-in-time** com o valor na tela, e trate os três estados como no iOS: concedida, negada,
  **negada permanentemente** (aí o caminho é o ajuste do sistema, com texto que explique o que se
  perde — nunca um loop de pedido). Em `targetSdk` ≥ 33 sem o pedido, **o app simplesmente não
  notifica**, e nenhum erro aparece no seu log.
- **Token morto tem de morrer.** APNs e FCM **dizem** quando o destino não existe mais
  (`Unregistered`/`410` no APNs; `UNREGISTERED`/`INVALID_ARGUMENT` no FCM): o worker de envio
  **apaga o registro na hora** que recebe essa resposta. Sem isso a base incha com fantasmas, a
  taxa de erro do projeto sobe e o provedor começa a **limitar o canal inteiro** — o push que
  importa (OTP, alerta) para de chegar por causa do que não importava. Complemente com **expiração
  por inatividade** (registro sem uso há N meses sai) e reconciliação periódica.

### 4.1 Push entra na suíte de testes

**Push não se testa mandando push de verdade** — isso é efeito externo, e efeito externo não sai de
não-produção (`schematize-engineering` → `references/efeitos-externos.md`). Testa-se contra um
**servidor falso de APNs/FCM** que grava o que teria sido enviado. Os casos:

| Caso | Prova |
|---|---|
| Registro na 1ª abertura e **em toda** abertura seguinte | o backend tem exatamente **um** registro por device — não dois, não zero |
| Token trocado pelo SO | o registro antigo é **substituído**, não somado |
| **Logout** | o token some do servidor **antes** do fim da sessão; um push endereçado ao usuário antigo não chega ao device |
| **Troca de usuário** no mesmo device | o push de A não chega enquanto B está logado |
| Permissão **negada** e **negada permanentemente** (iOS e Android 13+) | o app continua usável, explica o que se perde e **não** entra em loop de pedido |
| `targetSdk` ≥ 33 sem `POST_NOTIFICATIONS` | teste que **falha** — é o caso que passa despercebido porque não gera erro |
| Resposta `Unregistered`/`410`/`UNREGISTERED` do provedor | o registro é **apagado** na mesma execução |
| Payload com PII/segredo | o teste **reprova o envio**: payload é gatilho, não fonte de verdade nem cofre |
| Build de não-prd | não fala com o projeto de push de prd, e o backend de prd **recusa** o token (`entrega-lojas.md` §7) |
| Deep link vindo do push | abre a tela certa com o app fechado e com o usuário deslogado (`testes-mobile.md` §3) |

## 5. Assets e tamanho do app

- **App menor instala e converte mais:** app thinning / **App Bundle (Android)** e **on-demand
  resources / dynamic feature modules** pra não empacotar tudo. Imagens em formato eficiente
  (WebP/HEIC/vetor), sem assets órfãos.
- **Orçamento de tamanho** monitorado por release (regressão de tamanho é dívida rastreável).

## 6. Medir, não adivinhar (entra na DoD)

- **Perfile antes de otimizar:** Instruments (iOS), Android Studio Profiler/**Perfetto**, e — em
  React Native — o **React Native DevTools** (Hermes). ✔ Verificado em 2026-08-21: o **Flipper**
  saiu do RN por padrão na **0.73** (dez/2023) e foi substituído pelo DevTools novo; prescrevê-lo
  manda o time integrar uma ferramenta que o template já não traz —
  ache o gargalo real (CPU, alocação, jank, energia) em vez de "otimizar" o que não dói.
- **Métricas de gate:** cold start, jank/frozen frames, crash-free, consumo de bateria/rede em
  cenário padrão — acompanhadas por release (casa com `entrega-lojas.md` §6 e `observabilidade.md`).
- **Teste em device fraco e rede ruim:** o device topo de linha do dev mente. Matriz de teste inclui
  aparelho de baixo custo, SO antigo suportado, e rede throttled/offline.
