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

/// Um hábito do Monk Mode (ex.: "Ler 10 páginas").
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
    var reminderOn: Bool = false
    var reminderHour: Int = 18
    var reminderMinute: Int = 0

    init(title: String, period: DayPeriod, why: String = "", perWeek: Int = 7, avoid: Bool = false) {
        self.title = title
        self.period = period
        self.why = why
        self.perWeek = avoid ? 7 : perWeek
        self.avoid = avoid
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        period = try c.decodeIfPresent(DayPeriod.self, forKey: .period) ?? .qualquer
        why = try c.decodeIfPresent(String.self, forKey: .why) ?? ""
        perWeek = try c.decodeIfPresent(Int.self, forKey: .perWeek) ?? 7
        avoid = try c.decodeIfPresent(Bool.self, forKey: .avoid) ?? false
        reminderOn = try c.decodeIfPresent(Bool.self, forKey: .reminderOn) ?? false
        reminderHour = try c.decodeIfPresent(Int.self, forKey: .reminderHour) ?? 18
        reminderMinute = try c.decodeIfPresent(Int.self, forKey: .reminderMinute) ?? 0
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
    }
}

/// Atividades de "troca": o que fazer em vez de pegar o celular.
enum MindKind: String, Codable, CaseIterable, Identifiable {
    case ler, escrever, pensar, respirar, outro

    var id: String { rawValue }

    static let exercises: [MindKind] = [.pensar, .escrever, .ler, .respirar]

    var title: String {
        switch self {
        case .ler: return "Ler"
        case .escrever: return "Escrever"
        case .pensar: return "Pensar sem fazer nada"
        case .respirar: return "Respirar"
        case .outro: return "Outra troca"
        }
    }

    var subtitle: String {
        switch self {
        case .ler: return "Uma página de um livro de verdade"
        case .escrever: return "Algumas linhas sobre o que está na sua cabeça"
        case .pensar: return "Só você e uma pergunta. Sem tela."
        case .respirar: return "Devagar, para a cabeça baixar"
        case .outro: return ""
        }
    }

    var icon: String {
        switch self {
        case .ler: return "book"
        case .escrever: return "pencil.line"
        case .pensar: return "brain.head.profile"
        case .respirar: return "wind"
        case .outro: return "sparkles"
        }
    }

    var defaultMinutes: Int {
        switch self {
        case .ler: return 5
        case .escrever: return 3
        case .pensar: return 3
        case .respirar: return 1
        case .outro: return 0
        }
    }

    var minuteOptions: [Int] {
        switch self {
        case .respirar: return [1, 2, 3]
        case .ler: return [2, 5, 10, 20]
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
    /// A pergunta usada, ou o nome da troca rápida.
    var title: String = ""

    init(kind: MindKind, seconds: Int = 0, text: String = "", title: String = "") {
        self.kind = kind
        self.seconds = seconds
        self.text = text
        self.title = title
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        kind = try c.decodeIfPresent(MindKind.self, forKey: .kind) ?? .outro
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        seconds = try c.decodeIfPresent(Int.self, forKey: .seconds) ?? 0
        text = try c.decodeIfPresent(String.self, forKey: .text) ?? ""
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
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
        Habit(title: "Treinar", period: .qualquer, why: "Mais energia e cabeça mais leve"),
        Habit(title: "Beber 2L de água", period: .qualquer, why: "Menos cansaço e dor de cabeça"),
        Habit(title: "Dormir antes da meia-noite", period: .noite, why: "Acordar sem brigar com o despertador"),
        Habit(title: "Ler 10 páginas", period: .tarde, why: "Trocar scroll por ideias"),
        Habit(title: "Meditar 10 min", period: .manha, why: "Menos ansiedade, mais foco"),
        Habit(title: "1 hora de foco profundo", period: .tarde, why: "Avançar no que importa de verdade"),
        Habit(title: "Anotar os gastos do dia", period: .noite, why: "Saber pra onde vai o dinheiro"),
        Habit(title: "Celular fora do quarto", period: .noite, why: "Dormir melhor e acordar sem tela"),
        Habit(title: "Sem redes antes do meio-dia", period: .noite, why: "Manhã minha, não do feed", avoid: true),
        Habit(title: "Sem pornografia", period: .noite, why: "Mais controle e mais energia", avoid: true),
        Habit(title: "Sem álcool", period: .noite, why: "Sono e disposição melhores", avoid: true),
        Habit(title: "Sem doce", period: .noite, why: "Energia estável durante o dia", avoid: true),
    ]

    static let alternatives: [String] = [
        "ler uma página", "beber água", "olhar pela janela", "alongar 1 minuto",
        "anotar uma ideia", "respirar fundo 5 vezes", "arrumar algo perto de mim",
    ]
}
