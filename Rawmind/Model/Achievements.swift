import Foundation

/// Uma conquista ganha (guardada no celular).
struct AchievementRecord: Codable, Hashable {
    /// Quando foi ganha (ou ganha de novo, nas que renovam).
    var date: Date
    /// Quantas vezes foi ganha (as de semana e de mês renovam).
    var times: Int = 1

    init(date: Date, times: Int = 1) {
        self.date = date
        self.times = times
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        times = try c.decodeIfPresent(Int.self, forKey: .times) ?? 1
    }
}

/// Cor da medalha, da mais fácil para a mais difícil.
enum AchievementTier {
    case bronze, prata, ouro, lenda
}

/// Para sempre, ou renova toda semana / todo mês.
enum AchievementPeriod {
    case forever, week, month
}

/// Números usados para conferir as conquistas, calculados de uma vez.
struct AchievementStats {
    var pagesTotal = 0, pagesWeek = 0, pagesMonth = 0, books = 0
    var readingWeeks = 0, readingMonths = 0
    var mentePauses = 0, menteMinutes = 0, menteStreak = 0
    var writings = 0, words = 0, writingDays = 0
    var focusHours = 0, focusSessions = 0, pendencias = 0
    var criativas = 0, corpo = 0, caminhadas = 0, conversas = 0, pessoas = 0
    var monkStarted = 0, monkBest = 0, monkClean = 0
    var routineDays = 0
    var screenSaved = 0, yearDaysBack = 0, instagramCut = 0
    var swaps = 0
}

/// Uma conquista: o que precisa fazer e como aparece na medalha.
struct Achievement: Identifiable {
    let id: String
    let group: String
    let title: String
    /// O que precisa fazer, em poucas palavras.
    let detail: String
    let icon: String
    /// Texto dentro da medalha ("100", "7", "1h"). Nil = só o ícone.
    let badge: String?
    let tier: AchievementTier
    let goal: Int
    /// Unidade do "Faltam X ..." (ex.: "páginas").
    let unit: String
    let period: AchievementPeriod
    /// Frase da tela de comemoração.
    let celebration: String
    /// Progresso agora (nas que renovam: o progresso desta semana ou deste mês).
    let value: (AchievementStats) -> Int
    /// Quantas vezes já ganhou (só nas que renovam).
    let repeats: ((AchievementStats) -> Int)?

    init(_ id: String, _ group: String, _ title: String, _ detail: String,
         icon: String, badge: String?, tier: AchievementTier, goal: Int, unit: String,
         period: AchievementPeriod = .forever, celebration: String,
         value: @escaping (AchievementStats) -> Int,
         repeats: ((AchievementStats) -> Int)? = nil) {
        self.id = id
        self.group = group
        self.title = title
        self.detail = detail
        self.icon = icon
        self.badge = badge
        self.tier = tier
        self.goal = goal
        self.unit = unit
        self.period = period
        self.celebration = celebration
        self.value = value
        self.repeats = repeats
    }

    /// Quantas vezes já ganhou (0 = ainda não).
    func timesEarned(_ s: AchievementStats) -> Int {
        if let repeats { return repeats(s) }
        return value(s) >= goal ? 1 : 0
    }

    /// De 0 a 1, para a barrinha.
    func fraction(_ s: AchievementStats) -> Double {
        guard goal > 0 else { return 0 }
        return min(Double(max(value(s), 0)) / Double(goal), 1)
    }

    var renews: Bool { period != .forever }

    static func find(_ id: String) -> Achievement? { all.first { $0.id == id } }

    /// Grupos na ordem da página.
    static let groups = ["Leitura", "Mente", "Escrita", "Produtividade", "Criatividade", "Corpo",
                         "Pessoas", "Monk Mode", "Rotina matinal", "Tempo de tela", "Trocas"]

    /// A próxima do mesmo grupo, para mostrar depois de ganhar uma.
    func next(earned: Set<String>) -> Achievement? {
        Achievement.all.first { $0.group == group && !$0.renews && $0.id != id && !earned.contains($0.id) }
    }

    static let all: [Achievement] = [
        // Leitura
        Achievement("leitura-semana", "Leitura", "Semana de leitor", "10 páginas numa semana",
                    icon: "book", badge: "10", tier: .ouro, goal: 10, unit: "páginas", period: .week,
                    celebration: "10 páginas nesta semana. Toda semana que você bater, ganha de novo.",
                    value: { $0.pagesWeek }, repeats: { $0.readingWeeks }),
        Achievement("leitura-mes", "Leitura", "Mês de leitor", "50 páginas num mês",
                    icon: "book", badge: "50", tier: .ouro, goal: 50, unit: "páginas", period: .month,
                    celebration: "50 páginas neste mês. Mês que vem tem outra.",
                    value: { $0.pagesMonth }, repeats: { $0.readingMonths }),
        Achievement("paginas-100", "Leitura", "Primeiras 100", "100 páginas no total",
                    icon: "book", badge: "100", tier: .bronze, goal: 100, unit: "páginas",
                    celebration: "Você já leu 100 páginas. Dá um livro de bolso inteiro.",
                    value: { $0.pagesTotal }),
        Achievement("paginas-500", "Leitura", "Meio milhar", "500 páginas no total",
                    icon: "book", badge: "500", tier: .prata, goal: 500, unit: "páginas",
                    celebration: "500 páginas lidas. Isso é uns dois livros grandes.",
                    value: { $0.pagesTotal }),
        Achievement("paginas-1000", "Leitura", "Rato de biblioteca", "1.000 páginas no total",
                    icon: "book", badge: "1000", tier: .ouro, goal: 1000, unit: "páginas",
                    celebration: "Mil páginas lidas. Pouca gente chega aqui.",
                    value: { $0.pagesTotal }),
        Achievement("livro-1", "Leitura", "Primeiro livro", "Terminou um livro",
                    icon: "books.vertical", badge: "1", tier: .bronze, goal: 1, unit: "livro",
                    celebration: "Você terminou um livro inteiro.",
                    value: { $0.books }),
        Achievement("livro-5", "Leitura", "Estante", "5 livros terminados",
                    icon: "books.vertical", badge: "5", tier: .prata, goal: 5, unit: "livros",
                    celebration: "Cinco livros terminados. Já dá uma estante.",
                    value: { $0.books }),

        // Mente
        Achievement("mente-1", "Mente", "Primeira pausa", "Meditou, respirou ou pensou",
                    icon: "leaf", badge: nil, tier: .bronze, goal: 1, unit: "pausa",
                    celebration: "Primeira vez parando a cabeça em vez de rolar o feed.",
                    value: { $0.mentePauses }),
        Achievement("mente-60", "Mente", "1 hora de mente", "60 min somando tudo",
                    icon: "leaf", badge: "60", tier: .prata, goal: 60, unit: "minutos",
                    celebration: "Uma hora inteira pensando, respirando ou meditando.",
                    value: { $0.menteMinutes }),
        Achievement("mente-7", "Mente", "Cabeça fresca", "7 dias seguidos de mente",
                    icon: "lightbulb", badge: "7", tier: .ouro, goal: 7, unit: "dias",
                    celebration: "7 dias seguidos cuidando da cabeça.",
                    value: { $0.menteStreak }),

        // Escrita
        Achievement("escrita-1", "Escrita", "Primeira página", "Escreveu no caderno",
                    icon: "pencil", badge: nil, tier: .bronze, goal: 1, unit: "texto",
                    celebration: "Seu primeiro texto no caderno.",
                    value: { $0.writings }),
        Achievement("escrita-1000", "Escrita", "Mil palavras", "1.000 palavras escritas",
                    icon: "pencil", badge: "1000", tier: .prata, goal: 1000, unit: "palavras",
                    celebration: "1.000 palavras escritas por você, não pelo feed.",
                    value: { $0.words }),
        Achievement("escrita-30", "Escrita", "Diário", "30 dias escrevendo",
                    icon: "pencil", badge: "30", tier: .ouro, goal: 30, unit: "dias",
                    celebration: "30 dias escrevendo. Isso já é um diário.",
                    value: { $0.writingDays }),

        // Produtividade
        Achievement("foco-1", "Produtividade", "Primeiro foco", "Uma sessão de foco",
                    icon: "scope", badge: nil, tier: .bronze, goal: 1, unit: "sessão",
                    celebration: "Sua primeira sessão de foco. Celular longe, cabeça em uma coisa só.",
                    value: { $0.focusSessions }),
        Achievement("foco-10h", "Produtividade", "10 horas de foco", "Somando todas as sessões",
                    icon: "scope", badge: "10h", tier: .prata, goal: 10, unit: "horas",
                    celebration: "10 horas de foco profundo.",
                    value: { $0.focusHours }),
        Achievement("pendencias-10", "Produtividade", "Sem pendências", "10 pendências resolvidas",
                    icon: "checkmark.circle", badge: "10", tier: .ouro, goal: 10, unit: "pendências",
                    celebration: "10 pendências resolvidas. Menos coisa pesando na cabeça.",
                    value: { $0.pendencias }),

        // Criatividade
        Achievement("criativo-5", "Criatividade", "Mão na massa", "5 tarefas criativas",
                    icon: "paintbrush.pointed", badge: "5", tier: .bronze, goal: 5, unit: "tarefas",
                    celebration: "5 coisas criadas em vez de consumidas.",
                    value: { $0.criativas }),
        Achievement("criativo-25", "Criatividade", "Criador", "25 tarefas criativas",
                    icon: "paintbrush.pointed", badge: "25", tier: .prata, goal: 25, unit: "tarefas",
                    celebration: "25 tarefas criativas. Você faz coisas.",
                    value: { $0.criativas }),

        // Corpo
        Achievement("corpo-10", "Corpo", "Em movimento", "10 tarefas pro corpo",
                    icon: "figure.walk", badge: "10", tier: .bronze, goal: 10, unit: "tarefas",
                    celebration: "10 vezes mexendo o corpo em vez de pegar o celular.",
                    value: { $0.corpo }),
        Achievement("corpo-50", "Corpo", "Corpo ligado", "50 tarefas pro corpo",
                    icon: "figure.walk", badge: "50", tier: .prata, goal: 50, unit: "tarefas",
                    celebration: "50 vezes. Seu corpo agradece.",
                    value: { $0.corpo }),
        Achievement("caminhar-10", "Corpo", "Caminhante", "10 caminhadas sem celular",
                    icon: "figure.walk", badge: "10", tier: .ouro, goal: 10, unit: "caminhadas",
                    celebration: "10 caminhadas sem celular no bolso.",
                    value: { $0.caminhadas }),

        // Pessoas
        Achievement("conversa-5", "Pessoas", "Olho no olho", "5 conversas ao vivo",
                    icon: "person.2", badge: "5", tier: .bronze, goal: 5, unit: "conversas",
                    celebration: "5 conversas ao vivo, sem tela no meio.",
                    value: { $0.conversas }),
        Achievement("pessoas-20", "Pessoas", "Presente", "20 momentos com pessoas",
                    icon: "person.2", badge: "20", tier: .prata, goal: 20, unit: "momentos",
                    celebration: "20 momentos com gente de verdade.",
                    value: { $0.pessoas }),

        // Monk Mode
        Achievement("monk-1", "Monk Mode", "Dia 1", "Começou o Monk Mode",
                    icon: "flame", badge: "1", tier: .bronze, goal: 1, unit: "dia",
                    celebration: "Você começou o Monk Mode. O mais difícil é começar.",
                    value: { $0.monkStarted }),
        Achievement("monk-7", "Monk Mode", "Uma semana", "7 dias no Monk Mode",
                    icon: "flame", badge: "7", tier: .prata, goal: 7, unit: "dias",
                    celebration: "7 dias seguidos no Monk Mode.",
                    value: { $0.monkBest }),
        Achievement("monk-15", "Monk Mode", "Metade", "15 dias no Monk Mode",
                    icon: "flame", badge: "15", tier: .ouro, goal: 15, unit: "dias",
                    celebration: "15 dias. Metade do caminho.",
                    value: { $0.monkBest }),
        Achievement("monk-30", "Monk Mode", "Monge", "30 dias no Monk Mode",
                    icon: "flame", badge: "30", tier: .lenda, goal: 30, unit: "dias",
                    celebration: "30 dias completos. Você não é mais a mesma pessoa.",
                    value: { $0.monkBest }),
        Achievement("monk-limpo", "Monk Mode", "Sem desculpa", "30 dias sem segunda chance",
                    icon: "flame", badge: nil, tier: .lenda, goal: 1, unit: "Monk Mode",
                    celebration: "30 dias sem usar a segunda chance nenhuma vez.",
                    value: { $0.monkClean }),

        // Rotina matinal
        Achievement("rotina-7", "Rotina matinal", "Madrugador", "7 manhãs com a rotina",
                    icon: "sun.max", badge: "7", tier: .bronze, goal: 7, unit: "manhãs",
                    celebration: "7 manhãs com a rotina feita.",
                    value: { $0.routineDays }),
        Achievement("rotina-30", "Rotina matinal", "30 manhãs", "30 manhãs com a rotina",
                    icon: "sun.max", badge: "30", tier: .prata, goal: 30, unit: "manhãs",
                    celebration: "30 manhãs. Já está virando automático.",
                    value: { $0.routineDays }),
        Achievement("rotina-66", "Rotina matinal", "Hábito formado", "66 manhãs com a rotina",
                    icon: "sun.max", badge: "66", tier: .lenda, goal: 66, unit: "manhãs",
                    celebration: "66 manhãs. Agora é hábito de verdade.",
                    value: { $0.routineDays }),

        // Tempo de tela
        Achievement("tela-1h", "Tempo de tela", "1 hora de volta", "1h a menos por dia",
                    icon: "iphone.slash", badge: "1h", tier: .prata, goal: 60, unit: "min",
                    celebration: "Uma hora a menos de celular por dia.",
                    value: { $0.screenSaved }),
        Achievement("tela-10dias", "Tempo de tela", "10 dias por ano", "10 dias por ano de volta",
                    icon: "iphone.slash", badge: "10", tier: .ouro, goal: 10, unit: "dias",
                    celebration: "10 dias por ano de volta pra sua vida.",
                    value: { $0.yearDaysBack }),
        Achievement("tela-insta", "Tempo de tela", "Metade", "Metade do Instagram",
                    icon: "iphone.slash", badge: "½", tier: .lenda, goal: 50, unit: "%",
                    celebration: "Você cortou o Instagram pela metade.",
                    value: { $0.instagramCut }),

        // Trocas
        Achievement("trocas-10", "Trocas", "10 trocas", "10 trocas em vez do celular",
                    icon: "arrow.left.arrow.right", badge: "10", tier: .bronze, goal: 10, unit: "trocas",
                    celebration: "10 vezes você escolheu outra coisa em vez do celular.",
                    value: { $0.swaps }),
        Achievement("trocas-100", "Trocas", "100 trocas", "100 trocas em vez do celular",
                    icon: "arrow.left.arrow.right", badge: "100", tier: .prata, goal: 100, unit: "trocas",
                    celebration: "100 trocas. O celular está perdendo.",
                    value: { $0.swaps }),
        Achievement("trocas-500", "Trocas", "500 trocas", "500 trocas em vez do celular",
                    icon: "arrow.left.arrow.right", badge: "500", tier: .ouro, goal: 500, unit: "trocas",
                    celebration: "500 trocas. Você ganhou do celular.",
                    value: { $0.swaps }),
    ]
}

extension Store {
    /// Calcula tudo o que as conquistas precisam.
    var achievementStats: AchievementStats {
        var s = AchievementStats()
        let cal = Calendar.current
        var weekCal = Calendar.current
        weekCal.firstWeekday = 2
        let now = Date()
        let sessions = data.mindSessions

        // Leitura
        let reads = sessions.filter { $0.kind == .ler }
        s.pagesTotal = reads.reduce(0) { $0 + $1.pages }
        s.books = reads.filter(\.finishedBook).count
        var byWeek: [String: Int] = [:]
        var byMonth: [String: Int] = [:]
        for r in reads {
            let w = weekCal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: r.date)
            byWeek["\(w.yearForWeekOfYear ?? 0)-\(w.weekOfYear ?? 0)", default: 0] += r.pages
            byMonth[Store.monthKey(for: r.date), default: 0] += r.pages
        }
        s.readingWeeks = byWeek.values.filter { $0 >= 10 }.count
        s.readingMonths = byMonth.values.filter { $0 >= 50 }.count
        let thisWeek = weekCal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        s.pagesWeek = byWeek["\(thisWeek.yearForWeekOfYear ?? 0)-\(thisWeek.weekOfYear ?? 0)"] ?? 0
        s.pagesMonth = byMonth[Store.monthKey(for: now)] ?? 0

        // Mente
        let mente = sessions.filter { [MindKind.pensar, .meditar, .respirar].contains($0.kind) }
        s.mentePauses = mente.count
        s.menteMinutes = mente.reduce(0) { $0 + $1.seconds } / 60
        s.menteStreak = Store.longestStreak(mente.map { cal.startOfDay(for: $0.date) })

        // Escrita
        let writes = sessions.filter { $0.kind == .escrever }
        s.writings = writes.count
        s.words = writes.reduce(0) { $0 + $1.wordCount }
        s.writingDays = Set(writes.map { cal.startOfDay(for: $0.date) }).count

        // Produtividade (sessões do cadeado + tarefa "foco profundo")
        let focusTasks = sessions.filter { $0.activity == "foco" }
        let focusMinutes = totalFocusMinutes + focusTasks.reduce(0) { $0 + $1.seconds } / 60
        s.focusHours = focusMinutes / 60
        s.focusSessions = data.days.values.filter { $0.focusMinutes > 0 }.count + focusTasks.count
        s.pendencias = sessions.filter { $0.activity == "pendencia" }.count

        // Criatividade, corpo, pessoas
        s.criativas = activityCount(.criatividade, in: sessions)
        s.corpo = activityCount(.corpo, in: sessions)
        s.caminhadas = sessions.filter { $0.activity == "caminhar" }.count
        s.conversas = sessions.filter { $0.activity == "conversar" }.count
        s.pessoas = activityCount(.pessoas, in: sessions)

        // Monk Mode
        s.monkStarted = (data.monk != nil || !data.monkHistory.isEmpty) ? 1 : 0
        var current = 0
        if monkActive {
            current = monkAllDoneToday ? monkDay : monkDay - 1
        } else if monkCompleted {
            current = Store.monkDays
        }
        s.monkBest = min(max(monkRecord, current, 0), Store.monkDays)
        s.monkClean = data.monkHistory.contains { $0.end == .completed && !$0.usedSecondChance } ? 1 : 0

        // Rotina
        s.routineDays = completedDays

        // Tempo de tela
        if let base = data.screenBaseline, let latest = latestScreen {
            s.screenSaved = max(base.totalMinutes - latest.totalMinutes, 0)
            s.yearDaysBack = max(Store.daysPerYear(base.totalMinutes) - Store.daysPerYear(latest.totalMinutes), 0)
            if base.instagramMinutes > 0 {
                let cut = 100 - Int((Double(latest.instagramMinutes) / Double(base.instagramMinutes) * 100).rounded())
                s.instagramCut = min(max(cut, 0), 100)
            }
        }

        s.swaps = sessions.count
        return s
    }

    /// Maior número de dias seguidos.
    static func longestStreak(_ days: [Date]) -> Int {
        let sorted = Array(Set(days)).sorted()
        guard !sorted.isEmpty else { return 0 }
        var best = 1, run = 1
        for i in 1..<sorted.count {
            let gap = Calendar.current.dateComponents([.day], from: sorted[i - 1], to: sorted[i]).day ?? 0
            run = gap == 1 ? run + 1 : 1
            best = max(best, run)
        }
        return best
    }

    /// Ids das conquistas já ganhas.
    var earnedAchievements: Set<String> { Set(data.achievements.keys) }

    /// As últimas ganhas, da mais nova para a mais velha.
    var recentAchievements: [Achievement] {
        data.achievements.sorted { $0.value.date > $1.value.date }
            .compactMap { Achievement.find($0.key) }
    }

    /// As mais perto de serem ganhas (as que renovam contam se ainda não bateu neste período).
    func nearAchievements(_ s: AchievementStats, limit: Int = 3) -> [Achievement] {
        let earned = earnedAchievements
        let thisPeriodDone: (Achievement) -> Bool = { a in
            a.renews && a.value(s) >= a.goal
        }
        return Achievement.all
            .filter { a in
                a.goal > 1 && a.value(s) > 0 && a.value(s) < a.goal
                    && (a.renews ? !thisPeriodDone(a) : !earned.contains(a.id))
            }
            .sorted { $0.fraction(s) > $1.fraction(s) }
            .prefix(limit)
            .map { $0 }
    }
}
