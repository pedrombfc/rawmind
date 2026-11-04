import Foundation

/// O quanto a ciência apoia um guia.
enum Evidence: Hashable {
    case forte, moderada, inicial

    var label: String {
        switch self {
        case .forte: return "Forte"
        case .moderada: return "Moderada"
        case .inicial: return "Inicial"
        }
    }

    var long: String { "Evidência \(label.lowercased())" }
}

/// Um guia da aba Guias: como fazer um hábito e por que funciona.
/// Os passos aceitam **negrito** (markdown).
struct Guide: Identifiable, Hashable {
    let id: String
    let category: ActivityCategory
    let title: String
    let icon: String
    /// Quanto tempo leva ("5 a 10 min").
    let duration: String
    /// Quando fazer ("De manhã").
    let when: String
    let evidence: Evidence
    /// Uma frase: o que é e o que ganha.
    let summary: String
    let steps: [String]
    let why: String
    let science: String
    /// Quem não deve fazer ou como não exagerar. Nil = sem cuidados especiais.
    var care: String? = nil

    static func find(_ id: String) -> Guide? { all.first { $0.id == id } }

    /// O guia em destaque no topo ("Comece por aqui").
    static var featured: Guide { find("luz-sol") ?? all[0] }

    static let all: [Guide] = mente + produtividade + criatividade + corpo + pessoas

    // MARK: Mente

    static let mente: [Guide] = [
        Guide(id: "meditacao", category: .mente, title: "Meditação de atenção", icon: "brain",
              duration: "3 a 20 min", when: "A qualquer hora", evidence: .forte,
              summary: "Treinar a atenção voltando pra respiração toda vez que a cabeça foge.",
              steps: [
                "Sente num lugar confortável e feche os olhos.",
                "Preste atenção no ar entrando e saindo pelo nariz.",
                "A mente vai fugir. Quando perceber, **volte pra respiração** sem se cobrar.",
                "Comece com **3 a 5 minutos**. Com o tempo, suba até 10 ou 20.",
              ],
              why: "Cada vez que você percebe que se distraiu e volta, é uma repetição do treino. Isso fortalece o controle da atenção e diminui a mania de ficar remoendo pensamentos.",
              science: "Programas de meditação de atenção plena, como o MBSR, têm **evidência forte para reduzir estresse e ansiedade**. Para melhorar o foco, a evidência é moderada.",
              care: "Em quem passou por trauma, a meditação pode trazer emoções difíceis. Você pode parar a qualquer momento."),
        Guide(id: "body-scan", category: .mente, title: "Body scan", icon: "figure.mind.and.body",
              duration: "5 a 10 min", when: "Antes de dormir", evidence: .moderada,
              summary: "Passar a atenção pelo corpo, dos pés à cabeça, pra relaxar.",
              steps: [
                "Deite ou sente de um jeito confortável.",
                "Leve a atenção pros pés. Note o que sente ali, sem tentar mudar nada.",
                "Suba devagar: pernas, barriga, peito, braços, pescoço e rosto.",
                "Onde achar tensão, só perceba e siga em frente. Leva **5 a 10 minutos**.",
              ],
              why: "Tira a cabeça dos pensamentos e leva a atenção pro corpo. Isso ajuda o corpo a relaxar, principalmente antes de dormir.",
              science: "Faz parte dos programas de atenção plena estudados há décadas. A evidência para relaxar é moderada.",
              care: "Se alguma lembrança difícil aparecer, abra os olhos e pare. Tudo bem."),
        Guide(id: "suspiro", category: .mente, title: "Suspiro fisiológico", icon: "wind",
              duration: "1 a 5 min", when: "Na hora do estresse", evidence: .moderada,
              summary: "Duas puxadas de ar e uma soltada longa. O jeito mais rápido de baixar a agitação.",
              steps: [
                "Puxe o ar pelo nariz, bem fundo.",
                "Sem soltar, puxe **mais um pouquinho** por cima.",
                "Solte tudo **devagar pela boca**, numa expiração longa.",
                "Repita por **1 a 5 minutos**.",
              ],
              why: "Soltar o ar por mais tempo do que puxa ativa o freio natural do corpo. O coração desacelera e a agitação baixa em poucos minutos.",
              science: "Num estudo de Stanford de 2023, **5 minutos por dia** de suspiro fisiológico melhoraram o humor mais do que a meditação. A evidência ainda é moderada.",
              care: "Não faça debaixo d'água nem dirigindo. Se ficar tonto, volte a respirar normal."),
        Guide(id: "respiracao-quadrada", category: .mente, title: "Respiração quadrada", icon: "square",
              duration: "1 a 2 min", when: "A qualquer hora", evidence: .moderada,
              summary: "Respirar contando até 4, como os lados de um quadrado.",
              steps: [
                "Puxe o ar contando **4 segundos**.",
                "Segure o ar por **4 segundos**.",
                "Solte o ar em **4 segundos**.",
                "Fique sem ar por **4 segundos**. Faça de 4 a 6 rodadas.",
              ],
              why: "O ritmo lento e contado acalma o corpo e dá pra cabeça uma tarefa simples, que tira a atenção da preocupação.",
              science: "Respirar devagar tem evidência moderada para reduzir estresse. A versão quadrada em si foi pouco estudada sozinha.",
              care: "Não faça debaixo d'água nem dirigindo. Se ficar tonto, encurte as pausas."),
        Guide(id: "brain-dump", category: .mente, title: "Descarregar a mente", icon: "list.bullet.clipboard",
              duration: "5 min", when: "Antes de dormir", evidence: .moderada,
              summary: "Tirar tudo da cabeça e colocar no papel.",
              steps: [
                "Pegue um papel e marque **5 minutos**.",
                "Escreva tudo o que está na cabeça: tarefas, preocupações, ideias. Sem ordem.",
                "No fim, marque o que vira tarefa e quando você vai fazer.",
              ],
              why: "Coisas pendentes ficam rodando na mente o dia inteiro. Anotar, com um plano do que fazer, faz a cabeça soltar elas.",
              science: "Estudos sobre tarefas pendentes mostram que anotar um plano reduz pensamentos repetitivos. Escrever a lista antes de dormir ajudou pessoas a pegarem no sono mais rápido. Evidência moderada."),
        Guide(id: "escrita-expressiva", category: .mente, title: "Escrita expressiva", icon: "pencil.and.outline",
              duration: "15 a 20 min", when: "Quando algo incomoda", evidence: .moderada,
              summary: "Escrever sem parar sobre o que está pesando, pra ninguém ler.",
              steps: [
                "Escolha algo que está te incomodando.",
                "Escreva por **15 a 20 minutos** sem parar: o que aconteceu e o que você sente.",
                "Não corrija nada. Ninguém vai ler, nem você precisa reler.",
              ],
              why: "Colocar em palavras organiza o que aconteceu. A experiência fica mais fácil de entender e pesa menos.",
              science: "Estudada há décadas pelo psicólogo James Pennebaker. Os efeitos são pequenos, mas aparecem em muitos estudos. Evidência moderada.",
              care: "Logo depois de escrever, pode bater uma tristeza. Costuma passar. Se for algo muito pesado, converse com alguém de confiança."),
        Guide(id: "pensamento-critico", category: .mente, title: "Pensamento crítico", icon: "questionmark.bubble",
              duration: "2 min", when: "Antes de acreditar", evidence: .moderada,
              summary: "5 perguntas pra fazer antes de acreditar num post ou notícia.",
              steps: [
                "Quem disse isso e **o que ganha** com isso?",
                "Qual é a **prova**?",
                "O que diria **quem discorda**?",
                "Isso é **fato ou opinião**?",
                "O que **mudaria minha ideia**?",
              ],
              why: "As perguntas freiam o raciocínio automático e te obrigam a olhar a evidência antes de concordar ou compartilhar.",
              science: "Uma meta-análise de 2015 (Abrami) mostrou que ensinar pensamento crítico de forma direta melhora o desempenho. Evidência moderada."),
        Guide(id: "antes-ia", category: .mente, title: "Pensar antes da IA", icon: "eye",
              duration: "2 min", when: "Antes de pesquisar", evidence: .forte,
              summary: "Tentar sozinho antes de perguntar pra IA ou pro Google.",
              steps: [
                "Antes de perguntar pra IA ou pro Google, pare por **2 minutos**.",
                "Pense e escreva a sua resposta, mesmo que incompleta.",
                "Só depois pesquise e compare com o que você escreveu.",
              ],
              why: "Tentar lembrar ou resolver antes de ver a resposta faz o cérebro guardar muito melhor. Ler a resposta pronta passa rápido e some.",
              science: "O efeito de testagem e o efeito de geração têm **evidência forte** para o aprendizado. O uso com IA especificamente ainda é pouco estudado."),
    ]

    // MARK: Produtividade

    static let produtividade: [Guide] = [
        Guide(id: "planejar-dia", category: .produtividade, title: "Planejar o dia", icon: "list.number",
              duration: "5 min", when: "De manhã", evidence: .moderada,
              summary: "Escolher 3 tarefas e dar um horário pra cada uma.",
              steps: [
                "De manhã, ou na noite anterior, escolha as **3 tarefas mais importantes**.",
                "Coloque a mais difícil primeiro.",
                "Dê um **horário** pra cada uma.",
              ],
              why: "Quando você decide antes, não precisa decidir na hora em que a preguiça fala mais alto. É só seguir o plano.",
              science: "Estudos sobre metas específicas e planejamento mostram que quem planeja o que e quando faz cumpre mais. Evidência moderada."),
        Guide(id: "se-entao", category: .produtividade, title: "Plano Se... então...", icon: "arrow.triangle.branch",
              duration: "2 min", when: "Ao criar um hábito", evidence: .forte,
              summary: "Amarrar uma ação a um momento certo, pra fazer quase no automático.",
              steps: [
                "Escolha um momento ou lugar que acontece todo dia.",
                "Escreva: **\"Se for [momento], então eu [ação]\"**.",
                "Exemplo: \"Se eu pegar o celular esperando algo, então leio 1 página.\"",
              ],
              why: "O momento vira um gatilho. Quando ele acontece, o cérebro já sabe o que fazer e executa quase no automático.",
              science: "As intenções de implementação, de Peter Gollwitzer, têm **evidência forte**: uma meta-análise com 94 estudos mostrou efeito claro em cumprir metas."),
        Guide(id: "blocos-tempo", category: .produtividade, title: "Blocos de tempo", icon: "calendar",
              duration: "10 min", when: "Na noite anterior", evidence: .moderada,
              summary: "Dividir o dia em blocos, cada um com um tipo de tarefa.",
              steps: [
                "Abra o calendário e divida o dia em blocos.",
                "Cada bloco recebe **um tipo de trabalho** só.",
                "Proteja **1 a 2 blocos de foco** de 60 a 90 minutos, sem celular.",
              ],
              why: "Você para de pular de uma coisa pra outra e cria um compromisso marcado com você mesmo.",
              science: "É apoiado pela pesquisa sobre o custo de trocar de tarefa. Evidência moderada."),
        Guide(id: "pomodoro", category: .produtividade, title: "Pomodoro", icon: "timer",
              duration: "25 min", when: "Na hora de estudar", evidence: .moderada,
              summary: "25 minutos de foco, 5 de pausa. Repete.",
              steps: [
                "Deixe o celular **em outro cômodo**.",
                "Marque **25 minutos** e foque numa coisa só.",
                "Pause **5 minutos**. Levante, beba água.",
                "A cada 4 rodadas, faça uma pausa maior, de 15 a 30 minutos.",
              ],
              why: "Um prazo curto deixa mais fácil começar. As pausas marcadas evitam o cansaço.",
              science: "Estudos pequenos mostram mais foco e menos cansaço do que pausas sem horário. Evidência moderada."),
        Guide(id: "celular-longe", category: .produtividade, title: "Celular fora do alcance", icon: "iphone.slash",
              duration: "Durante o foco", when: "Estudo e trabalho", evidence: .inicial,
              summary: "O celular em outro cômodo, não só virado na mesa.",
              steps: [
                "Antes de estudar ou trabalhar, leve o celular **pra outro cômodo**.",
                "Virar a tela pra baixo não basta. Ele precisa sair da sua vista.",
                "Só volte pra ele na pausa.",
              ],
              why: "Só de ver o celular, parte da sua atenção fica presa nele, mesmo sem você perceber.",
              science: "Um estudo de 2017 chamado \"brain drain\" mostrou isso, mas outras pesquisas tiveram resultados mistos. Evidência inicial a moderada."),
        Guide(id: "dois-minutos", category: .produtividade, title: "Regra dos 2 minutos", icon: "stopwatch",
              duration: "2 min", when: "A qualquer hora", evidence: .inicial,
              summary: "Se leva menos de 2 minutos, faça agora.",
              steps: [
                "Se uma tarefa leva **menos de 2 minutos**, faça na hora.",
                "Pra tarefas grandes, combine com você: **só 2 minutos**.",
                "Depois de começar, decida se continua.",
              ],
              why: "Começar é a parte mais difícil. Depois que você começa, continuar fica muito mais fácil.",
              science: "É uma regra popular, mas pouco testada diretamente. Evidência inicial."),
        Guide(id: "uma-coisa", category: .produtividade, title: "Uma coisa por vez", icon: "1.circle",
              duration: "Durante o foco", when: "Estudo e trabalho", evidence: .forte,
              summary: "Fechar tudo o que não é da tarefa.",
              steps: [
                "Feche as abas e apps que **não são da tarefa**.",
                "Deixe um papel do lado.",
                "Lembrou de outra coisa? **Anote no papel** e volte pra tarefa.",
              ],
              why: "Cada troca de tarefa custa tempo e aumenta os erros. Fazer várias coisas ao mesmo tempo é uma ilusão.",
              science: "A pesquisa sobre o custo de trocar de tarefa tem **evidência forte**: alternar deixa tudo mais lento e com mais erros."),
        Guide(id: "revisao-dia", category: .produtividade, title: "Revisão do dia", icon: "moon.stars",
              duration: "3 min", when: "À noite", evidence: .moderada,
              summary: "3 perguntas pra fechar o dia e deixar amanhã pronto.",
              steps: [
                "À noite, responda: **o que eu fiz bem** hoje?",
                "**O que travou**?",
                "Qual é a **primeira tarefa** de amanhã?",
              ],
              why: "Fecha o dia, você aprende com ele e já acorda sabendo por onde começar.",
              science: "Um estudo de Harvard com funcionários mostrou que refletir alguns minutos no fim do dia melhorou o desempenho. Evidência moderada."),
    ]

    // MARK: Criatividade

    static let criatividade: [Guide] = [
        Guide(id: "escrita-livre", category: .criatividade, title: "Escrita livre", icon: "scribble",
              duration: "5 a 10 min", when: "A qualquer hora", evidence: .moderada,
              summary: "Escrever sem parar, sem apagar e sem corrigir.",
              steps: [
                "Marque **5 a 10 minutos**.",
                "Escreva sem parar, **sem apagar e sem corrigir**.",
                "Travou? Escreva \"não sei o que escrever\" até sair alguma coisa.",
              ],
              why: "Separa a hora de criar da hora de editar. O crítico interno que trava tudo fica desligado.",
              science: "É um método clássico no ensino de escrita. Evidência moderada."),
        Guide(id: "paginas-matinais", category: .criatividade, title: "Páginas matinais", icon: "sunrise",
              duration: "20 min", when: "Ao acordar", evidence: .inicial,
              summary: "3 páginas à mão logo ao acordar, do que vier à cabeça.",
              steps: [
                "Ao acordar, antes do celular, pegue um caderno.",
                "Escreva **3 páginas à mão**, ou umas 750 palavras.",
                "Vale qualquer coisa que vier à cabeça.",
              ],
              why: "Esvazia a cabeça antes do dia começar e cria o hábito de escrever todo dia.",
              science: "É popular entre escritores e artistas, mas foi pouco estudado. Evidência inicial."),
        Guide(id: "escrever-claro", category: .criatividade, title: "Escrever claro", icon: "text.alignleft",
              duration: "10 min", when: "Ao escrever um texto", evidence: .moderada,
              summary: "Uma ideia por frase, palavras simples.",
              steps: [
                "Antes do texto, escreva a **ideia principal em 1 frase**.",
                "Use frases curtas e palavras simples.",
                "Releia **em voz alta** e corte o que não faz falta.",
              ],
              why: "Texto claro vem de pensamento claro. Ler em voz alta mostra onde o texto trava.",
              science: "A pesquisa sobre legibilidade mostra que frases curtas e palavras comuns são entendidas mais rápido. Evidência moderada."),
        Guide(id: "feynman", category: .criatividade, title: "Técnica Feynman", icon: "graduationcap",
              duration: "10 min", when: "Depois de estudar", evidence: .moderada,
              summary: "Explicar algo como se fosse pra uma criança.",
              steps: [
                "Escolha algo que você estudou.",
                "Explique por escrito **como se fosse pra uma criança**, com palavras simples.",
                "Onde travar, volte pro material e estude aquela parte.",
              ],
              why: "Mostra exatamente o que você ainda não entendeu. Onde a explicação trava, está o buraco.",
              science: "A pesquisa sobre autoexplicação mostra que explicar com as próprias palavras melhora o aprendizado. Evidência moderada."),
        Guide(id: "ler-atencao", category: .criatividade, title: "Ler com atenção", icon: "book",
              duration: "10 a 15 min", when: "A qualquer hora", evidence: .moderada,
              summary: "Algumas páginas de livro e uma frase sobre o que aprendeu.",
              steps: [
                "Leia **5 a 10 páginas** de um livro de papel ou no modo leitura.",
                "Deixe o celular longe enquanto lê.",
                "No fim, escreva **1 frase** com o que aprendeu.",
              ],
              why: "Ler por mais tempo treina a atenção. Resumir no fim fixa o que você leu.",
              science: "Uma meta-análise de 2018 (Delgado) mostrou leve vantagem de compreensão na leitura em papel. Evidência moderada."),
        Guide(id: "dez-ideias", category: .criatividade, title: "10 ideias por dia", icon: "lightbulb",
              duration: "5 min", when: "A qualquer hora", evidence: .moderada,
              summary: "Listar 10 ideias sobre um tema, mesmo as ruins.",
              steps: [
                "Escolha um tema: um negócio, um presente, um problema pra resolver.",
                "Liste **10 ideias**, mesmo as ruins.",
                "Não pare nas primeiras. As boas costumam vir no fim.",
              ],
              why: "Quantidade gera qualidade. As melhores ideias costumam aparecer depois das óbvias.",
              science: "A pesquisa sobre geração de ideias mostra que quem produz mais ideias chega a ideias melhores. Evidência moderada."),
        Guide(id: "tedio", category: .criatividade, title: "Tédio de propósito", icon: "cloud",
              duration: "2 min", when: "Na fila ou esperando", evidence: .inicial,
              summary: "Esperar sem pegar nada e deixar a mente vagar.",
              steps: [
                "Na fila ou esperando alguém, **não pegue o celular**.",
                "Só observe o que está em volta.",
                "Deixe a mente vagar por **2 minutos**.",
              ],
              why: "Quando a mente vaga, ela conecta coisas que estavam soltas. É daí que vêm muitas ideias.",
              science: "Estudos sobre incubação e devaneio mostram um efeito pequeno nas ideias. Evidência inicial."),
    ]

    // MARK: Corpo

    static let corpo: [Guide] = [
        Guide(id: "luz-sol", category: .corpo, title: "Luz do sol ao acordar", icon: "sun.max",
              duration: "5 a 10 min", when: "Ao acordar", evidence: .forte,
              summary: "10 min ao ar livre que acertam seu sono e sua energia.",
              steps: [
                "Nos primeiros **30 a 60 minutos** do dia, saia ao ar livre.",
                "Fique **5 a 10 minutos** na luz do dia. Se estiver nublado, 15 a 20.",
                "Sem óculos escuros. E nunca olhe direto pro sol.",
              ],
              why: "A luz da manhã acerta o seu relógio biológico. Você fica com mais disposição de dia e dorme mais fácil à noite.",
              science: "O efeito da luz da manhã no relógio biológico tem **evidência forte**. O tempo exato de 5 a 10 minutos tem evidência moderada.",
              care: "Nunca olhe diretamente pro sol."),
        Guide(id: "cafe-tarde", category: .corpo, title: "Cortar café à tarde", icon: "cup.and.saucer",
              duration: "8 h antes de dormir", when: "À tarde", evidence: .forte,
              summary: "O último café pelo menos 8 horas antes de dormir.",
              steps: [
                "Tome o último café pelo menos **8 horas antes de dormir**.",
                "Exemplo: dorme às 23h, para às **15h**.",
                "Vale também pra energético, chá preto e pré-treino.",
              ],
              why: "A cafeína fica horas no corpo. Mesmo sem você perceber, café tarde demais tira parte do seu sono.",
              science: "Num estudo de 2013 (Drake), café 6 horas antes de dormir tirou **cerca de 1 hora de sono**. Uma revisão de 2023 indica parar umas 8 a 9 horas antes. Evidência forte."),
        Guide(id: "esperar-cafe", category: .corpo, title: "Esperar pro primeiro café", icon: "clock",
              duration: "60 a 90 min", when: "De manhã", evidence: .inicial,
              summary: "Água e sol primeiro, café depois.",
              steps: [
                "Ao acordar, beba **um copo de água**.",
                "Pegue um pouco de sol.",
                "Tome o café **60 a 90 minutos** depois de acordar.",
              ],
              why: "A ideia é evitar a queda de energia no meio da tarde. Muita gente diz que funciona, mas é opcional.",
              science: "Há pouca prova direta. Evidência inicial. Teste e veja como você se sente."),
        Guide(id: "banho-gelado", category: .corpo, title: "Banho gelado", icon: "snowflake",
              duration: "1 a 3 min", when: "De manhã", evidence: .moderada,
              summary: "Um choque curto de frio que acorda o corpo e treina você a ficar calmo no desconforto.",
              steps: [
                "Tome seu banho normal, na temperatura de sempre.",
                "No fim, gire para a água fria por **30 segundos**.",
                "Respire devagar, soltando o ar mais longo do que puxa. Não prenda a respiração.",
                "A cada semana, suba um pouco: até **1 a 3 minutos**.",
              ],
              why: "O frio dá um pico de alerta parecido com um café, sem a cafeína. E ficar calmo debaixo da água gelada é um treino: você aprende a não fugir do desconforto.",
              science: "Num estudo com 3.000 pessoas na Holanda, quem terminou o banho com 30 a 90 s de água fria teve **29% menos faltas por doença**. Promessas como \"mais testosterona\" ainda não têm boa prova.",
              care: "Tem problema de coração ou pressão alta? Fale com um médico antes. Nunca entre sozinho em rio, lago ou mar gelado."),
        Guide(id: "alongamento", category: .corpo, title: "Alongamento matinal", icon: "figure.flexibility",
              duration: "5 min", when: "De manhã", evidence: .moderada,
              summary: "6 alongamentos de 30 segundos pra soltar o corpo.",
              steps: [
                "Fique **30 segundos** em cada um:",
                "**Gato-vaca**: de quatro, arredonde e afunde as costas devagar.",
                "**Postura da criança**: sente nos calcanhares e estique os braços à frente no chão.",
                "**Afundo**: um joelho no chão, empurre o quadril pra frente. Troque de lado.",
                "**Torção deitado**: deitado, leve um joelho pro lado oposto. Troque de lado.",
                "**Peitoral na porta** e **pescoço de lado**, cada lado.",
              ],
              why: "Solta a rigidez da noite e ajuda o corpo a acordar.",
              science: "Alongar tem evidência moderada para melhorar a mobilidade e o conforto do corpo.",
              care: "Alongamento não deve doer, só puxar."),
        Guide(id: "pausa-mesa", category: .corpo, title: "Pausa de mesa", icon: "figure.stand",
              duration: "2 min", when: "A cada 30 a 60 min", evidence: .moderada,
              summary: "Levantar e se mexer um pouco a cada hora sentado.",
              steps: [
                "A cada **30 a 60 minutos** sentado, levante.",
                "Estique os braços acima da cabeça.",
                "Gire os ombros pra trás **10 vezes** e puxe o queixo pra dentro **5 vezes**.",
                "Ande um pouco antes de voltar.",
              ],
              why: "Quebrar o tempo sentado melhora a circulação e o açúcar no sangue, e diminui a dor nas costas e no pescoço.",
              science: "Evidência moderada: estudos mostram benefício em interromper longos períodos sentado."),
        Guide(id: "caminhada-refeicao", category: .corpo, title: "Caminhada depois de comer", icon: "figure.walk",
              duration: "10 a 15 min", when: "Depois das refeições", evidence: .forte,
              summary: "Uma volta leve depois do almoço ou do jantar.",
              steps: [
                "Depois do almoço ou do jantar, saia pra andar.",
                "Caminhe **10 a 15 minutos** em ritmo leve.",
                "Deixe o celular em casa ou no bolso.",
              ],
              why: "Os músculos usam o açúcar do sangue e diminuem o pico que vem depois da refeição.",
              science: "Uma meta-análise de 2022 mostrou que caminhar depois de comer reduz o pico de açúcar no sangue. Evidência forte."),
        Guide(id: "exercicio", category: .corpo, title: "Exercício regular", icon: "figure.run",
              duration: "30 min", when: "5 dias por semana", evidence: .forte,
              summary: "150 minutos por semana de exercício, mais 2 dias de força.",
              steps: [
                "Some **150 minutos por semana** de exercício moderado.",
                "Exemplo: 30 minutos, 5 dias por semana.",
                "Inclua **2 dias de força**: musculação, flexões, agachamentos.",
              ],
              why: "Melhora o humor, a memória e o sono, e diminui a ansiedade e a depressão.",
              science: "É a recomendação da OMS. Meta-análises mostram efeito na depressão comparável a tratamentos. Evidência forte."),
        Guide(id: "sono", category: .corpo, title: "Rotina de sono", icon: "bed.double",
              duration: "Toda noite", when: "À noite", evidence: .forte,
              summary: "O mesmo horário pra dormir e acordar, todo dia.",
              steps: [
                "Durma e acorde **no mesmo horário todo dia**, inclusive no fim de semana.",
                "Deixe o quarto escuro e fresco.",
                "Tire o celular da cama **30 a 60 minutos antes** de dormir.",
              ],
              why: "Dormir sempre no mesmo horário importa tanto quanto dormir bastante. O corpo aprende quando desligar.",
              science: "Ter um sono regular está ligado a melhor saúde e humor, tanto quanto a duração do sono. Evidência forte."),
    ]

    // MARK: Pessoas

    static let pessoas: [Guide] = [
        Guide(id: "mensagem", category: .pessoas, title: "Mandar mensagem de verdade", icon: "message",
              duration: "2 min", when: "Em vez de curtir", evidence: .moderada,
              summary: "Uma mensagem pessoal em vez de só curtir posts.",
              steps: [
                "Em vez de curtir posts, pense em **uma pessoa**.",
                "Mande uma mensagem pessoal: \"vi isso e lembrei de você\" ou \"como foi aquilo?\".",
                "Feche o app depois de mandar.",
              ],
              why: "Falar com alguém aproxima. Só ver o conteúdo dos outros não aproxima ninguém.",
              science: "Pesquisas comparam uso ativo e passivo das redes: conversar faz bem, só rolar o feed não. Evidência moderada."),
        Guide(id: "ligar", category: .pessoas, title: "Ligar em vez de digitar", icon: "phone",
              duration: "5 min", when: "Uma vez por dia", evidence: .moderada,
              summary: "Uma ligação curta pra um amigo ou alguém da família.",
              steps: [
                "Escolha um amigo ou alguém da família.",
                "Em vez de mandar texto, **ligue**.",
                "**5 minutos** já bastam.",
              ],
              why: "A voz cria mais conexão do que texto. E as pessoas subestimam o quanto o outro vai gostar da ligação.",
              science: "Um estudo de 2021 (Kumar e Epley) mostrou que ligar cria mais conexão do que digitar, e não é tão estranho quanto parece. Evidência moderada."),
        Guide(id: "tres-coisas", category: .pessoas, title: "Três coisas boas", icon: "star",
              duration: "3 min", when: "À noite", evidence: .moderada,
              summary: "Anotar 3 coisas boas do dia e por que aconteceram.",
              steps: [
                "À noite, pegue um papel.",
                "Escreva **3 coisas boas** que aconteceram hoje.",
                "Do lado de cada uma, escreva **por que** aconteceu.",
              ],
              why: "Treina a atenção pra perceber o que dá certo, e isso melhora o humor.",
              science: "Estudado por Martin Seligman em 2005. O efeito no humor é pequeno a moderado. Evidência moderada."),
        Guide(id: "gratidao", category: .pessoas, title: "Mensagem de gratidão", icon: "envelope",
              duration: "10 min", when: "Quando quiser", evidence: .moderada,
              summary: "Agradecer alguém dizendo exatamente o que fez por você.",
              steps: [
                "Pense em alguém que te ajudou.",
                "Escreva **exatamente o que a pessoa fez** e como isso te ajudou.",
                "**Envie**. Por carta, mensagem ou lendo pra ela.",
              ],
              why: "Fortalece a relação e aumenta o bem-estar de quem escreve, não só de quem recebe.",
              science: "Estudos sobre cartas de gratidão mostram aumento de bem-estar. Evidência moderada."),
        Guide(id: "conversa", category: .pessoas, title: "Conversa sem celular", icon: "person.2",
              duration: "Na refeição", when: "Refeições e encontros", evidence: .moderada,
              summary: "Celulares guardados e uma pergunta de verdade.",
              steps: [
                "Em refeições ou encontros, **guardem os celulares**.",
                "Faça uma **pergunta aberta**, que não se responde com sim ou não.",
                "Escute até o fim, sem pensar no que vai responder.",
              ],
              why: "Só ter o celular na mesa já diminui a sensação de conexão na conversa.",
              science: "Um estudo de 2018 (Dwyer) mostrou que quem jantou com o celular na mesa curtiu menos o encontro. Evidência moderada."),
    ]
}
