import Foundation

/// Um item da rotina matinal (ex.: "Água ao acordar").
struct RoutineItem: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var why: String
}

enum DayPeriod: String, Codable, CaseIterable, Identifiable {
    case manha = "Manhã"
    case tarde = "Tarde"
    case noite = "Noite"
    case qualquer = "Qualquer hora"

    var id: String { rawValue }
}

/// Horário de um lembrete.
struct HabitReminder: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var hour: Int
    var minute: Int

    init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    var text: String { String(format: "%02d:%02d", hour, minute) }
}

/// Ícones que a pessoa pode escolher para um hábito (símbolos da Apple).
enum HabitIcons {
    static let all: [String] = [
        "book", "book.closed", "books.vertical", "pencil.line", "note.text", "graduationcap",
        "brain.head.profile", "lightbulb", "figure.mind.and.body", "leaf", "sun.max", "sunrise",
        "moon.zzz", "bed.double", "drop", "cup.and.saucer", "fork.knife", "carrot",
        "figure.run", "figure.walk", "figure.yoga", "dumbbell", "bicycle", "heart",
        "lungs", "flame", "bolt", "target", "star", "checkmark.seal",
        "dollarsign.circle", "chart.line.uptrend.xyaxis", "laptopcomputer", "music.note", "paintbrush", "camera",
        "globe", "person.2", "phone", "house", "iphone.slash", "nosign",
        "hand.raised", "wineglass", "snowflake", "clock", "calendar", "list.bullet",
    ]
}

/// Um hábito do Monk Mode (ex.: "Ler 10 páginas"). Todo dia, durante os 30 dias.
struct Habit: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var period: DayPeriod
    /// "O que você espera que mude" (a hipótese).
    var why: String = ""
    /// Vezes por semana (7 = todo dia).
    var perWeek: Int = 7
    /// Hábito de "evitar" (ex.: sem redes antes do meio-dia). Confirmado à noite.
    var avoid: Bool = false
    /// Nome do ícone (símbolo da Apple).
    var icon: String = "flame"
    /// Até 2 lembretes por dia.
    var reminders: [HabitReminder] = []

    init(title: String, period: DayPeriod = .qualquer, why: String = "", perWeek: Int = 7, avoid: Bool = false, icon: String = "flame") {
        self.title = title
        self.period = period
        self.why = why
        self.perWeek = avoid ? 7 : perWeek
        self.avoid = avoid
        self.icon = icon
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, period, why, perWeek, avoid, icon, reminders
        case reminderOn, reminderHour, reminderMinute
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(period, forKey: .period)
        try c.encode(why, forKey: .why)
        try c.encode(perWeek, forKey: .perWeek)
        try c.encode(avoid, forKey: .avoid)
        try c.encode(icon, forKey: .icon)
        try c.encode(reminders, forKey: .reminders)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        period = try c.decodeIfPresent(DayPeriod.self, forKey: .period) ?? .qualquer
        why = try c.decodeIfPresent(String.self, forKey: .why) ?? ""
        perWeek = try c.decodeIfPresent(Int.self, forKey: .perWeek) ?? 7
        avoid = try c.decodeIfPresent(Bool.self, forKey: .avoid) ?? false
        icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? (avoid ? "nosign" : "flame")
        if let list = try c.decodeIfPresent([HabitReminder].self, forKey: .reminders) {
            reminders = list
        } else if try c.decodeIfPresent(Bool.self, forKey: .reminderOn) == true {
            // Versão antiga: um lembrete só.
            let h = try c.decodeIfPresent(Int.self, forKey: .reminderHour) ?? 18
            let m = try c.decodeIfPresent(Int.self, forKey: .reminderMinute) ?? 0
            reminders = [HabitReminder(hour: h, minute: m)]
        }
    }

    /// Texto curto ao lado do hábito na lista ("Evitar", "08:00" ou nada).
    var sideText: String {
        if avoid { return "Evitar" }
        return reminders.first?.text ?? ""
    }

    var frequencyText: String {
        if avoid { return "Evitar" }
        return perWeek >= 7 ? "Todo dia" : "\(perWeek)x por semana"
    }

    /// Quantas vezes o hábito precisa ser feito nos 30 dias.
    var target: Int {
        max(1, Int((Double(Store.phase1) * Double(min(perWeek, 7)) / 7).rounded()))
    }
}

/// O que a pessoa decide no fim dos 30 dias.
enum HabitDecision: String, Codable, CaseIterable, Identifiable {
    case manter = "Manter"
    case ajustar = "Ajustar"
    case largar = "Largar"

    var id: String { rawValue }

    var detail: String {
        switch self {
        case .manter: return "Continua na fase 2, até 66 dias"
        case .ajustar: return "Muda alguma coisa e tenta de novo"
        case .largar: return "Não fez sentido pra você, tudo bem"
        }
    }
}

struct HabitConclusion: Codable, Hashable {
    var text: String
    var decision: HabitDecision
    var date: Date = Date()
}

/// O que foi feito em um dia.
struct DayRecord: Codable, Hashable {
    var routineDone: Set<UUID> = []
    var routineCompleted: Bool = false
    var habitsDone: Set<UUID> = []
    var focusMinutes: Int = 0
    /// Nota curta do dia para cada hábito ("como foi").
    var habitNotes: [String: String] = [:]

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        routineDone = try c.decodeIfPresent(Set<UUID>.self, forKey: .routineDone) ?? []
        routineCompleted = try c.decodeIfPresent(Bool.self, forKey: .routineCompleted) ?? false
        habitsDone = try c.decodeIfPresent(Set<UUID>.self, forKey: .habitsDone) ?? []
        focusMinutes = try c.decodeIfPresent(Int.self, forKey: .focusMinutes) ?? 0
        habitNotes = try c.decodeIfPresent([String: String].self, forKey: .habitNotes) ?? [:]
    }
}

/// Tudo o que o app guarda no celular.
struct AppData: Codable {
    var onboarded: Bool = false
    var startDate: Date? = nil
    var routine: [RoutineItem] = []
    var routineHour: Int = 7
    var routineMinute: Int = 0
    var habits: [Habit] = []
    var alternatives: [String] = []
    /// Chave = "aaaa-mm-dd".
    var days: [String: DayRecord] = [:]
    /// Conclusão de cada hábito no fim dos 30 dias (chave = id do hábito).
    var conclusions: [String: HabitConclusion] = [:]
    /// Trocas feitas (ler, escrever, pensar...).
    var mindSessions: [MindSession] = []
    /// Tempo de tela antes de começar.
    var screenBaseline: ScreenTimeEntry? = nil
    /// Registros semanais depois de começar.
    var screenEntries: [ScreenTimeEntry] = []
    /// Monk Mode em andamento (nil = parado).
    var monk: MonkRun? = nil
    /// Tentativas que já acabaram.
    var monkHistory: [MonkAttempt] = []
    /// Meses ("aaaa-mm") em que a segunda chance já foi usada.
    var secondChancesUsed: [String] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        onboarded = try c.decodeIfPresent(Bool.self, forKey: .onboarded) ?? false
        startDate = try c.decodeIfPresent(Date.self, forKey: .startDate)
        routine = try c.decodeIfPresent([RoutineItem].self, forKey: .routine) ?? []
        routineHour = try c.decodeIfPresent(Int.self, forKey: .routineHour) ?? 7
        routineMinute = try c.decodeIfPresent(Int.self, forKey: .routineMinute) ?? 0
        habits = try c.decodeIfPresent([Habit].self, forKey: .habits) ?? []
        alternatives = try c.decodeIfPresent([String].self, forKey: .alternatives) ?? []
        days = try c.decodeIfPresent([String: DayRecord].self, forKey: .days) ?? [:]
        conclusions = try c.decodeIfPresent([String: HabitConclusion].self, forKey: .conclusions) ?? [:]
        mindSessions = try c.decodeIfPresent([MindSession].self, forKey: .mindSessions) ?? []
        screenBaseline = try c.decodeIfPresent(ScreenTimeEntry.self, forKey: .screenBaseline)
        screenEntries = try c.decodeIfPresent([ScreenTimeEntry].self, forKey: .screenEntries) ?? []
        monk = try c.decodeIfPresent(MonkRun.self, forKey: .monk)
        monkHistory = try c.decodeIfPresent([MonkAttempt].self, forKey: .monkHistory) ?? []
        secondChancesUsed = try c.decodeIfPresent([String].self, forKey: .secondChancesUsed) ?? []
    }
}

/// Um Monk Mode em andamento: 30 dias, todos os hábitos, todo dia.
struct MonkRun: Codable, Hashable {
    var startDate: Date
    /// Hábitos travados neste Monk Mode.
    var habitIDs: [UUID]
    var attempt: Int = 1
    /// Dias perdoados com a segunda chance ("aaaa-mm-dd").
    var forgivenDays: [String] = []
    /// Último dia já conferido e aprovado ("aaaa-mm-dd").
    var checkedThrough: String? = nil
    /// Dia que falhou e ainda espera a decisão da pessoa.
    var failure: MonkFailure? = nil
    /// Quando os 30 dias foram completados.
    var completedAt: Date? = nil

    init(startDate: Date, habitIDs: [UUID], attempt: Int) {
        self.startDate = startDate
        self.habitIDs = habitIDs
        self.attempt = attempt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        startDate = try c.decodeIfPresent(Date.self, forKey: .startDate) ?? Date()
        habitIDs = try c.decodeIfPresent([UUID].self, forKey: .habitIDs) ?? []
        attempt = try c.decodeIfPresent(Int.self, forKey: .attempt) ?? 1
        forgivenDays = try c.decodeIfPresent([String].self, forKey: .forgivenDays) ?? []
        checkedThrough = try c.decodeIfPresent(String.self, forKey: .checkedThrough)
        failure = try c.decodeIfPresent(MonkFailure.self, forKey: .failure)
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt)
    }
}

/// Um dia em que faltou hábito.
struct MonkFailure: Codable, Hashable {
    var dayKey: String
    var dayNumber: Int
    var missing: [UUID]
}

enum MonkEnd: String, Codable {
    case completed, failed, quit
}

/// Uma tentativa de Monk Mode que já acabou.
struct MonkAttempt: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var startDate: Date
    var endDate: Date = Date()
    var daysCompleted: Int
    var end: MonkEnd

    init(startDate: Date, daysCompleted: Int, end: MonkEnd) {
        self.startDate = startDate
        self.daysCompleted = daysCompleted
        self.end = end
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        startDate = try c.decodeIfPresent(Date.self, forKey: .startDate) ?? Date()
        endDate = try c.decodeIfPresent(Date.self, forKey: .endDate) ?? Date()
        daysCompleted = try c.decodeIfPresent(Int.self, forKey: .daysCompleted) ?? 0
        end = try c.decodeIfPresent(MonkEnd.self, forKey: .end) ?? .failed
    }
}

/// Atividades de "troca": o que fazer em vez de pegar o celular.
enum MindKind: String, Codable, CaseIterable, Identifiable {
    case ler, escrever, pensar, respirar, meditar, outro

    var id: String { rawValue }

    static let exercises: [MindKind] = [.pensar, .escrever, .ler, .respirar, .meditar]
    /// Cartões "Em vez do celular" na tela Hoje.
    static let activities: [MindKind] = [.ler, .escrever, .pensar, .respirar, .meditar, .outro]

    /// Nome curto para os cartões.
    var shortTitle: String { self == .pensar ? "Pensar" : title }

    var title: String {
        switch self {
        case .ler: return "Ler"
        case .escrever: return "Escrever"
        case .pensar: return "Pensar sem fazer nada"
        case .respirar: return "Respirar"
        case .meditar: return "Meditar"
        case .outro: return "Outra coisa"
        }
    }

    var subtitle: String {
        switch self {
        case .ler: return "Uma página de um livro de verdade"
        case .escrever: return "Algumas linhas sobre o que está na sua cabeça"
        case .pensar: return "Só você e uma pergunta. Sem tela."
        case .respirar: return "Devagar, para a cabeça baixar"
        case .meditar: return "Olhos fechados, atenção no ar"
        case .outro: return "Registrar o que você fez"
        }
    }

    var icon: String {
        switch self {
        case .ler: return "book"
        case .escrever: return "pencil.line"
        case .pensar: return "brain.head.profile"
        case .respirar: return "wind"
        case .meditar: return "figure.mind.and.body"
        case .outro: return "plus"
        }
    }

    var defaultMinutes: Int {
        switch self {
        case .ler: return 5
        case .escrever: return 3
        case .pensar: return 3
        case .respirar: return 1
        case .meditar: return 5
        case .outro: return 0
        }
    }

    var minuteOptions: [Int] {
        switch self {
        case .respirar: return [1, 2, 3]
        case .ler: return [2, 5, 10, 20]
        case .meditar: return [3, 5, 10, 15]
        default: return [1, 3, 5, 10]
        }
    }
}

/// Uma troca feita (ex.: 3 minutos pensando).
struct MindSession: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var kind: MindKind
    var date: Date = Date()
    var seconds: Int = 0
    /// O que a pessoa escreveu (ou anotou depois de pensar/ler).
    var text: String = ""
    /// A pergunta usada, o nome da troca rápida ou o livro.
    var title: String = ""
    /// Páginas lidas (só em "ler").
    var pages: Int = 0
    /// Terminou o livro nesta leitura.
    var finishedBook: Bool = false

    init(kind: MindKind, seconds: Int = 0, text: String = "", title: String = "", pages: Int = 0, finishedBook: Bool = false) {
        self.kind = kind
        self.seconds = seconds
        self.text = text
        self.title = title
        self.pages = pages
        self.finishedBook = finishedBook
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        kind = try c.decodeIfPresent(MindKind.self, forKey: .kind) ?? .outro
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        seconds = try c.decodeIfPresent(Int.self, forKey: .seconds) ?? 0
        text = try c.decodeIfPresent(String.self, forKey: .text) ?? ""
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        pages = try c.decodeIfPresent(Int.self, forKey: .pages) ?? 0
        finishedBook = try c.decodeIfPresent(Bool.self, forKey: .finishedBook) ?? false
    }

    var wordCount: Int {
        text.split { $0.isWhitespace || $0.isNewline }.count
    }
}

/// Tempo de tela anotado pela pessoa (média por dia).
struct ScreenTimeEntry: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var totalMinutes: Int
    var instagramMinutes: Int
    /// Vezes que pegou o celular por dia (0 = não informado).
    var pickups: Int = 0

    init(totalMinutes: Int, instagramMinutes: Int, pickups: Int = 0) {
        self.totalMinutes = totalMinutes
        self.instagramMinutes = instagramMinutes
        self.pickups = pickups
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        totalMinutes = try c.decodeIfPresent(Int.self, forKey: .totalMinutes) ?? 0
        instagramMinutes = try c.decodeIfPresent(Int.self, forKey: .instagramMinutes) ?? 0
        pickups = try c.decodeIfPresent(Int.self, forKey: .pickups) ?? 0
    }
}

/// Perguntas para pensar e escrever.
enum Prompts {
    static let think: [String] = [
        "O que você faria hoje se não existisse celular?",
        "Qual problema seu você ainda não parou pra pensar de verdade?",
        "Uma ideia que é só sua, que não veio de nenhum vídeo.",
        "Quem você quer ser daqui a 30 dias?",
        "O que te deixou entediado hoje? O que isso diz sobre você?",
        "Do que você sentiu falta essa semana?",
        "Se você tivesse uma tarde livre sem tela, o que faria?",
        "Qual decisão você está adiando?",
    ]

    static let write: [String] = [
        "O que estava na sua cabeça agora, antes de pegar o celular?",
        "Três coisas que aconteceram hoje.",
        "Uma coisa que você aprendeu essa semana.",
        "O que está te travando agora?",
        "Pelo que você é grato hoje?",
        "Uma conversa que você quer ter e ainda não teve.",
        "Como foi a sua manhã sem tela?",
    ]

    static func pick(_ list: [String], _ seed: Int) -> String {
        list[((seed % list.count) + list.count) % list.count]
    }
}

/// Sugestões que o app oferece.
enum Library {
    static let routine: [RoutineItem] = [
        RoutineItem(title: "Primeira hora sem celular", why: "Sua cabeça começa o dia sem a pauta dos outros"),
        RoutineItem(title: "Água ao acordar", why: "Você passou a noite inteira sem beber nada"),
        RoutineItem(title: "Luz natural · 10 min", why: "Luz forte de manhã ajusta seu relógio biológico"),
        RoutineItem(title: "10 min de movimento", why: "Acorda o corpo antes da tela"),
        RoutineItem(title: "Plano do dia no papel", why: "Três prioridades, escritas à mão"),
        RoutineItem(title: "Arrumar a cama", why: "Primeira tarefa do dia feita em 1 minuto"),
        RoutineItem(title: "Ler 5 páginas", why: "Começar com uma ideia, não com um feed"),
        RoutineItem(title: "Respirar 2 min", why: "Calma antes da correria"),
    ]

    static let habits: [Habit] = [
        Habit(title: "Treinar", why: "Mais energia e cabeça mais leve", icon: "dumbbell"),
        Habit(title: "Beber 2L de água", why: "Menos cansaço e dor de cabeça", icon: "drop"),
        Habit(title: "Dormir antes da meia-noite", why: "Acordar sem brigar com o despertador", icon: "moon.zzz"),
        Habit(title: "Ler 10 páginas", why: "Trocar scroll por ideias", icon: "book"),
        Habit(title: "Meditar 10 min", why: "Menos ansiedade, mais foco", icon: "figure.mind.and.body"),
        Habit(title: "1 hora de foco profundo", why: "Avançar no que importa de verdade", icon: "brain.head.profile"),
        Habit(title: "Anotar os gastos do dia", why: "Saber pra onde vai o dinheiro", icon: "dollarsign.circle"),
        Habit(title: "Celular fora do quarto", why: "Dormir melhor e acordar sem tela", icon: "iphone.slash"),
        Habit(title: "Sem redes antes do meio-dia", why: "Manhã minha, não do feed", avoid: true, icon: "nosign"),
        Habit(title: "Sem pornografia", why: "Mais controle e mais energia", avoid: true, icon: "hand.raised"),
        Habit(title: "Sem álcool", why: "Sono e disposição melhores", avoid: true, icon: "wineglass"),
        Habit(title: "Sem doce", why: "Energia estável durante o dia", avoid: true, icon: "nosign"),
    ]

    static let alternatives: [String] = [
        "ler uma página", "beber água", "olhar pela janela", "alongar 1 minuto",
        "anotar uma ideia", "respirar fundo 5 vezes", "arrumar algo perto de mim",
    ]
}
