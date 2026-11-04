# Rawmind

App iOS de disciplina contra a procrastinação e o celular ("lock in" é o slogan). Público: geração Z. iOS primeiro (SwiftUI), Android depois. Sem conta, sem nuvem, sem social, sem pagamento no MVP.

## Como trabalhar com o Pedro (ler primeiro)

- Pedro fala português. Responda **em português**, curto e simples.
- **Pedro não programa.** Claude escreve e compila o código; Pedro guia o produto. Não peça para ele editar código nem rodar comandos complicados.
- **Desenho antes de código.** Para qualquer mudança visual, mostre primeiro uma prévia (mockup em HTML/imagem) e espere o "ok". Só depois mexa no Swift.
- Depois de compilar, tire prints do simulador em `screenshots/`, seguindo a numeração que já existe (o último round foi o 58–67, Guias). Mostre os prints para ele aprovar.
- **Nunca apague os dados do Pedro no simulador.** Não desinstale o app, não resete o simulador, não use "Recomeçar". Antes de instalar uma build nova, faça backup dos dados e confira depois que continuam iguais (veja "Rodar no simulador").
- Se ele estiver usando o simulador, pergunte antes de instalar por cima.
- Campos novos em `AppData` sempre com `decodeIfPresent` e valor padrão, para não perder os dados já salvos.

## Decisões de produto (já tomadas, não reabrir sem o Pedro pedir)

- **Abas** (nesta ordem): Hoje, Monk Mode, Guias, Progresso, Ajustes.
- **Rotina matinal**: sempre ligada, separada do Monk Mode. Itens escolhidos pela pessoa. Fase 1 até o dia 30, fase 2 até o dia 66. 2 dias de reserva por semana. A sequência nunca zera de forma humilhante.
- **Monk Mode**: desafio sério que a pessoa liga com "Iniciar Monk Mode". Escolhe de 5 a 10 hábitos, que ficam travados por 30 dias. Precisa marcar todos até a meia-noite, senão o Monk Mode acaba e volta pro dia 1. Há 1 segunda chance por mês. Formulário do hábito: ícone (40+), nome, mudança esperada e até 2 lembretes. Não tem frequência nem duração. Encerrar fica em Ajustes.
- **Hoje**:
  - No topo: data, cadeado âmbar de foco no canto superior direito e tempo de tela ganho.
  - Depois: cartão da Rotina e cartão do Monk Mode.
  - Depois: "Em vez do celular", com as seções Mente, Produtividade, Criatividade, Corpo e Pessoas. Os cartões têm 148x100 e rolam para o lado. O título da seção abre a lista completa, e cada tarefa tem timer ou "Já fiz".
  - Por último: "Fiz outra coisa".
  - Sem quadrinhos de estatística (Pedro pediu para tirar). Espaçamento 24 entre as partes.
- **Ler** registra páginas, o livro e "terminei o livro".
- **Progresso**:
  - Cartão de Conquistas: as 3 últimas e uma lista "Quase lá" com barras.
  - Tempo de tela antes x agora (digitado à mão toda semana por enquanto).
  - Mente e caderno.
  - "Seu mês" foi substituído pelas conquistas.
- **Conquistas**: 37 medalhas hexagonais com ícone, nos níveis bronze, prata, ouro e lenda (verde). Os tipos são semana, mês (renovam e mostram "×3") e para sempre. Ganhar uma abre a tela "Nova conquista" com Compartilhar (imagem de story). Nunca comemorar retroativo: na primeira abertura as conquistas já atingidas são gravadas em silêncio.
- **Guias**:
  - Aba própria com 37 guias de hábitos em 5 categorias.
  - Cada guia tem como fazer, por que funciona, o que a ciência diz, cuidados e um selo de evidência (Forte, Moderada ou Inicial).
  - A tela tem busca, chips de categoria e "Comece por aqui" (Luz do sol).
  - **Não** ligar os guias aos cartões do Hoje nem ao Monk Mode (decisão do Pedro).
  - Só texto, sem vídeo.
- **Escudo (Screen Time)**: ainda não existe, porque precisa de conta Apple Developer (Pedro ainda não tem). Regras já decididas:
  - A tela de escudo da Apple só aceita 2 botões: "Fechar" (principal) e "Outras opções".
  - "Outras opções" manda uma notificação, que abre a tela Escolha no app com "Fazer algo melhor" e "Continuar mesmo assim".
  - "Continuar mesmo assim" tem pausa de 10/15/20 s e depois libera uma sessão curta de 5, 10 ou 15 min.
  - O microdesafio é uma **alternativa** e **nunca** libera o app.
  - O tom é neutro nas primeiras 4 tentativas do dia e mais direto a partir da 5ª, sem humilhar.
- **Apagar com swipe**: mostra só o ícone vermelho de lixeira, sem texto.
- **Visual**:
  - Cores: fundo #0E0E0C, cartão #1A1916, texto #EDEBE4, apoio #9A978E, acento único âmbar #F2A93B, verde "feito" #7FB8A4.
  - Fontes: títulos em Archivo, texto em Inter.

## Como o código está organizado

Projeto Xcode `Rawmind.xcodeproj`, esquema `Rawmind`, SwiftUI, iOS 17, Swift 5, bundle id `com.pedrombfc.rawmind`. O projeto usa pastas sincronizadas (objectVersion 77): **qualquer arquivo `.swift` novo dentro de `Rawmind/` entra no build sozinho**, sem mexer no `project.pbxproj`.

```
Rawmind/
  App/RawmindApp.swift      início do app, barra de 5 abas, tela de falha do Monk Mode, tela de conquista
  App/Theme.swift           cores (Theme.bg, .card, .text, .muted, .accent, .done...), fontes .archivo() e .inter()
  Model/Models.swift        tipos salvos (AppData, Habit, MonkAttempt, MindSession, ...)
  Model/Store.swift         @Observable Store: carrega/salva JSON em UserDefaults "rawmind.data.v1", regras, modos demo
  Model/Activities.swift    catálogo "Em vez do celular" (5 categorias)
  Model/Achievements.swift  as 37 conquistas e o cálculo delas
  Model/Guides.swift        os 37 guias (texto)
  Model/Notifications.swift lembretes
  Views/Components          botões, CheckBox, ThinBar, Chip, FlowLayout, SectionLabel, modificadores
  Views/Onboarding          primeira abertura
  Views/Today               Hoje, Rotina, Foco, Tempo de tela, Progresso (ProgressScreen.swift)
  Views/Mind                tarefas, timer, ler (ReadLogView), trocas e caderno
  Views/MonkMode            Monk Mode, início do desafio, hábito e formulário
  Views/Progress            medalhas (MedalView) e telas de conquistas
  Views/Guides              aba Guias e tela do guia
  Views/Settings            Ajustes e editores
  Resources/Fonts           Archivo e Inter
```

Regras do código:
- Para mudar dados, use `store.update { ... }`. Ele salva e recalcula as conquistas.
- Toda `.sheet` ou `.fullScreenCover` nova precisa de `.trackedModal()`. Assim a tela de "Nova conquista" não abre por cima de outra tela.
- Use `Theme` e as fontes `.archivo(...)` e `.inter(...)`. Não invente cores novas.
- Não use `LazyVGrid` dentro de cartões numa `ScrollView` (a altura fica errada). Use linhas de `HStack`.
- Textos do app em português do Brasil.

## Rodar no simulador (Mac do Pedro, Xcode 26, iPhone 17 Pro)

Jeito simples: abrir `Rawmind.xcodeproj`, escolher "iPhone 17 Pro" e apertar ▶︎ (Cmd+R).

Pela linha de comando (o que o Claude usa):

```sh
cd ~/Desktop/Rawmind
xattr -cr .   # sem isso a assinatura falha por atributos do macOS (com.apple.provenance)
xcodebuild -project Rawmind.xcodeproj -scheme Rawmind \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Rawmind-rc build
# O derivedDataPath fica fora da Mesa de propósito: dentro dela, a assinatura falha.

# backup dos dados do Pedro ANTES de instalar
DATA=$(xcrun simctl get_app_container booted com.pedrombfc.rawmind data)
cp "$DATA/Library/Preferences/com.pedrombfc.rawmind.plist" ~/rawmind-backup.plist

xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/Rawmind-rc/Build/Products/Debug-iphonesimulator/Rawmind.app
xcrun simctl launch booted com.pedrombfc.rawmind
xcrun simctl io booted screenshot screenshots/68-nome.png
```

Depois de instalar, confira se os dados continuam iguais ao backup.

Modos de demonstração (só em DEBUG). Ficam só na memória e **não salvam nada**, então servem para prints sem estragar os dados reais:

```sh
xcrun simctl launch booted com.pedrombfc.rawmind -demoMonk ativo        # Monk Mode no meio, com tarefas feitas
xcrun simctl launch booted com.pedrombfc.rawmind -demoMonk falha        # tela de falha / segunda chance
xcrun simctl launch booted com.pedrombfc.rawmind -demoMonk fim          # desafio de 30 dias concluído
xcrun simctl launch booted com.pedrombfc.rawmind -demoMonk onboarding   # primeira abertura
xcrun simctl launch booted com.pedrombfc.rawmind -demoCelebrate paginas-100   # tela de "Nova conquista" (qualquer id de Achievements.swift)
```

Depois dos prints, abra o app de novo sem argumentos para voltar aos dados reais.

## Git

Esta pasta é um clone de `github.com/pedrombfc/rawmind` (branch `main`). O GitHub serve só de cópia: a pasta do Mac é a fonte. Faça um commit por rodada, com mensagem clara. Dar push para `main` é opcional, mas mantém a cópia em dia.

## O que falta

- **Escudo / Screen Time de verdade**: FamilyControls, ManagedSettings e DeviceActivity. Precisa da conta Apple Developer e do entitlement Family Controls. Enquanto isso, o tempo de tela é digitado à mão toda semana.
- Telas ainda não desenhadas:
  - fluxo de "volta sem culpa" depois de pausar o escudo
  - check-in da noite
  - nova sessão de foco
  - visual dos Ajustes
- O primeiro toque em "Compartilhar" de uma conquista demora ~3 s no simulador. Ainda não foi investigado.
- `ActivityCategory.monthLabel` ficou sem uso desde que "Seu mês" saiu e pode ser apagado.
- `LEIA-ME.md` está desatualizado (é da v0.1). Este arquivo é a referência.
- Android, depois.

## Documentos

- Ideia e estrutura do app: https://claude.ai/artifact/2QnCShNRTgsBmuGPbG1dWE
- Pesquisa de concorrentes e estudos: https://claude.ai/artifact/CQX73f46i8iTSQsPJAxxEj
- Canvas de design das telas: https://claude.ai/artifact/WB6SUXnyyRcDbNbUocaLCb
- Biblioteca de guias (fonte do texto de `Guides.swift`): https://claude.ai/artifact/E2xxhQAtgKw1Cfr3hNE2yv
- Prévia das conquistas: https://claude.ai/artifact/5Y2kFu8c94fwnkf5P2MMEG
