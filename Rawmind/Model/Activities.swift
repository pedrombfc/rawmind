import Foundation

/// Seções de "Em vez do celular" na tela Hoje.
enum ActivityCategory: String, CaseIterable, Identifiable, Hashable {
    case mente, produtividade, criatividade, corpo, pessoas

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mente: return "Mente"
        case .produtividade: return "Produtividade"
        case .criatividade: return "Criatividade"
        case .corpo: return "Corpo"
        case .pessoas: return "Pessoas"
        }
    }

    var subtitle: String {
        switch self {
        case .mente: return "Pra cabeça baixar o volume."
        case .produtividade: return "Coisas pequenas que destravam o dia."
        case .criatividade: return "Fazer alguma coisa em vez de consumir."
        case .corpo: return "Levantar e mexer. O celular fica."
        case .pessoas: return "Gente de verdade, sem tela no meio."
        }
    }

    /// Rótulo do quadrinho no "Seu mês".
    var monthLabel: String {
        switch self {
        case .mente: return "de mente"
        case .produtividade: return "de produtividade"
        case .criatividade: return "criativas"
        case .corpo: return "pro corpo"
        case .pessoas: return "com pessoas"
        }
    }

    var activities: [Activity] { Activity.catalog.filter { $0.category == self } }
}

/// Uma tarefa para fazer em vez de pegar o celular.
/// As de mente (ler, pensar...) abrem as telas que já existem; as outras usam o timer genérico.
struct Activity: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
    let minutes: Int
    let category: ActivityCategory
    /// O que fazer, em uma ou duas frases.
    let hint: String
    /// Quando é uma das telas de mente.
    var mind: MindKind? = nil

    var minuteOptions: [Int] {
        if let mind { return mind.minuteOptions }
        switch minutes {
        case ...1: return [1, 2, 3]
        case 2...3: return [1, 3, 5]
        case 4...5: return [3, 5, 10]
        case 6...10: return [5, 10, 15]
        case 11...15: return [10, 15, 30]
        case 16...25: return [15, 25, 45]
        default: return [15, 30, 45]
        }
    }

    static func fromMind(_ kind: MindKind, _ category: ActivityCategory) -> Activity {
        Activity(id: kind.rawValue, title: kind.shortTitle, icon: kind.icon, minutes: kind.defaultMinutes,
                 category: category, hint: kind.subtitle, mind: kind)
    }

    static let catalog: [Activity] = [
        // Mente
        .fromMind(.ler, .mente),
        .fromMind(.pensar, .mente),
        .fromMind(.meditar, .mente),
        .fromMind(.respirar, .mente),

        // Produtividade
        Activity(id: "foco", title: "Foco profundo", icon: "scope", minutes: 25, category: .produtividade,
                 hint: "Escolha uma coisa só e trabalhe nela até o timer acabar. Celular longe."),
        Activity(id: "planejar", title: "Planejar o dia", icon: "list.bullet", minutes: 5, category: .produtividade,
                 hint: "Num papel, escreva as 3 coisas que fariam o dia valer a pena."),
        Activity(id: "quarto", title: "Arrumar o quarto", icon: "bed.double", minutes: 10, category: .produtividade,
                 hint: "Comece pela cama. Depois o que estiver no chão."),
        Activity(id: "mesa", title: "Organizar a mesa", icon: "tray.full", minutes: 5, category: .produtividade,
                 hint: "Tire tudo que não é pra agora. Mesa limpa, cabeça mais leve."),
        Activity(id: "pendencia", title: "Resolver uma pendência", icon: "checkmark.circle", minutes: 10, category: .produtividade,
                 hint: "Aquela coisa que você está adiando há dias. Só ela."),

        // Criatividade
        .fromMind(.escrever, .criatividade),
        Activity(id: "desenhar", title: "Desenhar", icon: "paintbrush.pointed", minutes: 10, category: .criatividade,
                 hint: "Papel e caneta. Não precisa ficar bonito, precisa sair da cabeça."),
        Activity(id: "musica", title: "Tocar música", icon: "guitars", minutes: 15, category: .criatividade,
                 hint: "Pegue o instrumento, ou só cante. Sem gravar, sem postar."),
        Activity(id: "cozinhar", title: "Cozinhar algo novo", icon: "fork.knife", minutes: 30, category: .criatividade,
                 hint: "Uma receita que você nunca fez. Pode ser simples."),
        Activity(id: "ideias", title: "Anotar ideias", icon: "lightbulb", minutes: 5, category: .criatividade,
                 hint: "Num caderno, tudo o que passar pela cabeça. Sem filtro."),

        // Corpo
        Activity(id: "alongar", title: "Alongar", icon: "figure.flexibility", minutes: 5, category: .corpo,
                 hint: "Pescoço, ombros, costas e pernas. Devagar, sem pressa."),
        Activity(id: "caminhar", title: "Caminhar sem celular", icon: "figure.walk", minutes: 15, category: .corpo,
                 hint: "Deixe o celular em casa e dê uma volta no quarteirão."),
        Activity(id: "flexoes", title: "Flexões", icon: "dumbbell", minutes: 3, category: .corpo,
                 hint: "Quantas você conseguir. Se cansar, descansa e faz mais uma série."),
        Activity(id: "agua", title: "Beber água", icon: "drop", minutes: 1, category: .corpo,
                 hint: "Um copo cheio, sem pressa. Seu corpo agradece."),
        Activity(id: "dancar", title: "Dançar uma música", icon: "figure.dance", minutes: 3, category: .corpo,
                 hint: "Coloque uma música que você gosta e mexa o corpo até ela acabar."),

        // Pessoas
        Activity(id: "conversar", title: "Conversar ao vivo", icon: "person.2", minutes: 10, category: .pessoas,
                 hint: "Vá até alguém da sua casa e puxe assunto. Olho no olho."),
        Activity(id: "familia", title: "Ligar pra família", icon: "phone", minutes: 10, category: .pessoas,
                 hint: "Uma ligação de voz pra alguém que você não vê faz tempo."),
        Activity(id: "ajudar", title: "Ajudar em casa", icon: "heart", minutes: 10, category: .pessoas,
                 hint: "Lavar a louça, pôr a mesa, ajudar alguém com alguma coisa."),
    ]

    static func find(_ id: String) -> Activity? { catalog.first { $0.id == id } }
}

extension Store {
    /// Vezes que a tarefa foi feita hoje.
    func activitySessionsToday(_ activity: Activity) -> [MindSession] {
        let today = mindSessions(on: Date())
        if let mind = activity.mind { return today.filter { $0.kind == mind } }
        return today.filter { $0.activity == activity.id }
    }

    /// Tarefas do catálogo (fora as de mente) feitas numa categoria.
    func activityCount(_ category: ActivityCategory, in sessions: [MindSession]) -> Int {
        sessions.filter { !$0.activity.isEmpty && Activity.find($0.activity)?.category == category }.count
    }
}
