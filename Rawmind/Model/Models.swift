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
