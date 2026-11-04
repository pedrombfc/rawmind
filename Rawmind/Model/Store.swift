import Foundation
import Observation

struct DayCount: Identifiable, Hashable {
    let date: Date
    let count: Int
    var id: Date { date }
}

struct NoteEntry: Identifiable, Hashable {
    let key: String
    let text: String
    var id: String { key }
}

/// Como foi um dia do protocolo.
enum DayStatus {
    case done      // rotina completa
    case reserve   // não fez, mas usou um dia de reserva
    case missed    // não fez e as reservas da semana acabaram
    case today     // hoje, ainda em aberto
    case future
}

/// Guarda e calcula tudo do app. Os dados ficam salvos no próprio celular.
@Observable
final class Store {
    static let phase1 = 30
    static let phase2 = 66
    static let reservesPerWeek = 2
    /// Monk Mode: 30 dias, de 5 a 10 hábitos.
    static let monkDays = 30
    static let minHabits = 5
    static let maxHabits = 10
    /// Lembrete do prazo (antes da meia-noite).
    static let deadlineReminderHour = 22

    private(set) var data: AppData
    private let storageKey = "rawmind.data.v1"
    /// Modo de demonstração (só no simulador): nada é salvo nem agendado.
    private var isDemo = false
    /// Conquistas novas esperando a tela de comemoração (ids).
    var celebrations: [String] = []
    /// Quantas folhas (sheets) estão abertas agora. A comemoração espera elas fecharem.
    var openModals = 0

    init() {
        if let raw = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(AppData.self, from: raw) {
            data = decoded
        } else {
            data = AppData()
        }
        #if DEBUG
        if let mode = UserDefaults.standard.string(forKey: "demoMonk") {
            seedDemo(mode)
        }
        #endif
        refreshAchievements()
        save()
        #if DEBUG
        if let id = UserDefaults.standard.string(forKey: "demoCelebrate"), Achievement.find(id) != nil {
            celebrations = [id]
        }
        #endif
    }

    // MARK: Gravar

    func update(_ change: (inout AppData) -> Void) {
        change(&data)
        refreshAchievements()
        save()
    }

    private func save() {
        guard !isDemo else { return }
        if let raw = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(raw, forKey: storageKey)
        }
    }

    func reset() {
        data = AppData()
        save()
        Notifications.cancelAll()
    }

    // MARK: Datas

    private var calendar: Calendar { Calendar.current }

    static func key(for date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    var todayKey: String { Store.key(for: Date()) }

    /// "aaaa-mm-dd" -> data.
    static func date(fromKey key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    /// "aaaa-mm" (para a segunda chance do mês).
    static func monthKey(for date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

    private func daysBetween(_ a: Date, _ b: Date) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: a), to: calendar.startOfDay(for: b)).day ?? 0
    }

    var today: DayRecord { data.days[todayKey] ?? DayRecord() }

    /// Dia do protocolo (1 = primeiro dia).
    var dayNumber: Int {
        guard let start = data.startDate else { return 1 }
        let a = calendar.startOfDay(for: start)
        let b = calendar.startOfDay(for: Date())
        return (calendar.dateComponents([.day], from: a, to: b).day ?? 0) + 1
    }

    /// Meta atual: 30 dias (fase 1), depois 66 (fase 2).
    var phaseTarget: Int { dayNumber <= Store.phase1 ? Store.phase1 : Store.phase2 }

    func date(forDay day: Int) -> Date? {
        guard let start = data.startDate else { return nil }
        return calendar.date(byAdding: .day, value: day - 1, to: calendar.startOfDay(for: start))
    }

    // MARK: Rotina e hábitos

    func isRoutineItemDone(_ item: RoutineItem) -> Bool {
        today.routineDone.contains(item.id)
    }

    var routineDoneCount: Int {
        data.routine.filter { today.routineDone.contains($0.id) }.count
    }

    var routineComplete: Bool {
        !data.routine.isEmpty && routineDoneCount == data.routine.count
    }

    func toggleRoutineItem(_ item: RoutineItem) {
        let key = todayKey
        update { d in
            var rec = d.days[key] ?? DayRecord()
            if rec.routineDone.contains(item.id) {
                rec.routineDone.remove(item.id)
            } else {
                rec.routineDone.insert(item.id)
            }
            let ids = Set(d.routine.map(\.id))
            rec.routineCompleted = !ids.isEmpty && ids.isSubset(of: rec.routineDone)
            d.days[key] = rec
        }
    }

    func isHabitDone(_ habit: Habit) -> Bool {
        today.habitsDone.contains(habit.id)
    }

    func toggleHabit(_ habit: Habit) {
        guard monkActive else { return }
        let key = todayKey
        update { d in
            var rec = d.days[key] ?? DayRecord()
            if rec.habitsDone.contains(habit.id) {
                rec.habitsDone.remove(habit.id)
            } else {
                rec.habitsDone.insert(habit.id)
            }
            d.days[key] = rec
        }
        evaluateMonk()
        refreshMonkReminders()
    }

    // MARK: Monk Mode (desafio)

    /// Em andamento (ainda não completou os 30 dias).
    var monkActive: Bool { data.monk != nil && data.monk?.completedAt == nil }

    var monkCompleted: Bool { data.monk?.completedAt != nil }

    /// Dia do Monk Mode (1 = primeiro dia).
    var monkDay: Int {
        guard let run = data.monk else { return 0 }
        return daysBetween(run.startDate, Date()) + 1
    }

    /// Hábitos travados no Monk Mode atual.
    var monkHabits: [Habit] {
        guard let run = data.monk else { return [] }
        return run.habitIDs.compactMap { id in data.habits.first { $0.id == id } }
    }

    var monkDoneToday: Int { monkHabits.filter { isHabitDone($0) }.count }

    var monkAllDoneToday: Bool { !monkHabits.isEmpty && monkDoneToday == monkHabits.count }

    /// Ainda tem a segunda chance do mês desta data?
    func hasSecondChance(for date: Date = Date()) -> Bool {
        !data.secondChancesUsed.contains(Store.monthKey(for: date))
    }

    /// Melhor tentativa (dias completos).
    var monkRecord: Int { data.monkHistory.map(\.daysCompleted).max() ?? 0 }

    var monkAttempts: Int { data.monkHistory.count + (monkActive ? 1 : 0) }

    /// Fim do prazo de hoje (meia-noite).
    var midnight: Date {
        calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? Date()
    }

    func startMonk(with habits: [Habit]) {
        for old in data.habits where !habits.contains(where: { $0.id == old.id }) {
            Notifications.cancelHabit(old)
        }
        let attempt = data.monkHistory.count + 1
        let start = calendar.startOfDay(for: Date())
        update { d in
            d.habits = habits
            d.monk = MonkRun(startDate: start, habitIDs: habits.map(\.id), attempt: attempt)
        }
        if !isDemo { habits.forEach { Notifications.scheduleHabit($0) } }
        refreshMonkReminders()
    }

    /// Confere os dias que já acabaram. Se faltou hábito, guarda a falha para a pessoa decidir.
    func evaluateMonk() {
        guard var run = data.monk, run.completedAt == nil, run.failure == nil else { return }
        let start = calendar.startOfDay(for: run.startDate)
        let todayNumber = daysBetween(start, Date()) + 1
        var day = 1
        if let k = run.checkedThrough, let checked = Store.date(fromKey: k) {
            day = daysBetween(start, checked) + 2
        }
        let before = run
        while day < todayNumber && day <= Store.monkDays {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: start) else { break }
            let key = Store.key(for: date)
            let done = data.days[key]?.habitsDone ?? []
            let missing = run.habitIDs.filter { !done.contains($0) }
            if missing.isEmpty || run.forgivenDays.contains(key) {
                run.checkedThrough = key
                day += 1
            } else {
                run.failure = MonkFailure(dayKey: key, dayNumber: day, missing: missing)
                break
            }
        }
        // Completo: os 30 dias passaram, ou o dia 30 já está todo marcado.
        var completed = false
        if run.failure == nil {
            if day > Store.monkDays {
                completed = true
            } else if day == Store.monkDays && todayNumber == Store.monkDays {
                let done = data.days[todayKey]?.habitsDone ?? []
                completed = !run.habitIDs.isEmpty && run.habitIDs.allSatisfy { done.contains($0) }
            }
        }
        if completed { run.completedAt = Date() }
        guard run != before else { return }
        let finished = run
        update { d in
            d.monk = finished
            if completed {
                d.monkHistory.append(MonkAttempt(startDate: finished.startDate, daysCompleted: Store.monkDays, end: .completed,
                                                 usedSecondChance: !finished.forgivenDays.isEmpty))
            }
        }
        refreshMonkReminders()
    }

    /// Perdoa o dia que falhou (uma vez por mês).
    func useSecondChance() {
        guard let f = data.monk?.failure,
              let date = Store.date(fromKey: f.dayKey),
              hasSecondChance(for: date) else { return }
        update { d in
            d.secondChancesUsed.append(Store.monthKey(for: date))
            d.monk?.forgivenDays.append(f.dayKey)
            d.monk?.failure = nil
        }
        evaluateMonk()
        refreshMonkReminders()
    }

    /// Aceita a falha: o Monk Mode acaba. Pode recomeçar na hora com os mesmos hábitos.
    func acceptMonkFailure(restart: Bool) {
        guard let run = data.monk, let f = run.failure else { return }
        let habits = monkHabits
        update { d in
            d.monkHistory.append(MonkAttempt(startDate: run.startDate, daysCompleted: max(f.dayNumber - 1, 0), end: .failed))
            d.monk = nil
        }
        if restart {
            startMonk(with: habits)
        } else {
            stopMonkNotifications()
        }
    }

    /// Desistir pelo Ajustes.
    func quitMonk() {
        guard let run = data.monk else { return }
        let days = min(max(monkDay - 1, 0), Store.monkDays)
        update { d in
            if run.completedAt == nil {
                d.monkHistory.append(MonkAttempt(startDate: run.startDate, daysCompleted: days, end: .quit))
            }
            d.monk = nil
        }
        stopMonkNotifications()
    }

    private func stopMonkNotifications() {
        guard !isDemo else { return }
        data.habits.forEach { Notifications.cancelHabit($0) }
        Notifications.scheduleMonkDeadlines([])
    }

    /// Lembrete às 22h de cada dia que ainda falta (hoje some quando tudo está marcado).
    func refreshMonkReminders() {
        guard !isDemo else { return }
        guard let run = data.monk, monkActive, run.failure == nil else {
            Notifications.scheduleMonkDeadlines([])
            return
        }
        let start = calendar.startOfDay(for: run.startDate)
        var list: [(date: Date, day: Int)] = []
        let first = max(monkDay, 1)
        guard first <= Store.monkDays else {
            Notifications.scheduleMonkDeadlines([])
            return
        }
        for day in first...Store.monkDays {
            guard let base = calendar.date(byAdding: .day, value: day - 1, to: start),
                  let fire = calendar.date(bySettingHour: Store.deadlineReminderHour, minute: 0, second: 0, of: base),
                  fire > Date() else { continue }
            if day == monkDay && monkAllDoneToday { continue }
            list.append((date: fire, day: day))
        }
        Notifications.scheduleMonkDeadlines(list)
    }

    enum MonkDayState { case done, forgiven, today, future, missed }

    /// Como foi o dia `n` do Monk Mode (para o calendário de 30 dias).
    func monkDayState(_ n: Int) -> MonkDayState {
        guard let run = data.monk,
              let date = calendar.date(byAdding: .day, value: n - 1, to: calendar.startOfDay(for: run.startDate))
        else { return .future }
        let current = monkDay
        if n > current { return .future }
        let key = Store.key(for: date)
        if run.forgivenDays.contains(key) { return .forgiven }
        let done = data.days[key]?.habitsDone ?? []
        let all = !run.habitIDs.isEmpty && run.habitIDs.allSatisfy { done.contains($0) }
        if n == current { return all ? .done : .today }
        return all ? .done : .missed
    }

    /// Dias do Monk Mode atual já completos (antes de hoje).
    var monkCompletedDays: Int {
        guard data.monk != nil else { return 0 }
        if monkCompleted { return Store.monkDays }
        return min(max(monkDay - 1, 0), Store.monkDays)
    }

    /// Dias em que o hábito foi feito neste Monk Mode.
    func habitDoneDays(_ habit: Habit) -> Int {
        let from = data.monk.map { Store.key(for: $0.startDate) } ?? ""
        return data.days.filter { $0.key >= from && $0.value.habitsDone.contains(habit.id) }.count
    }

    func isHabitDone(_ habit: Habit, on date: Date) -> Bool {
        data.days[Store.key(for: date)]?.habitsDone.contains(habit.id) ?? false
    }

    /// Feitos nesta semana (segunda a domingo do calendário do celular).
    func habitDoneThisWeek(_ habit: Habit) -> Int {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        var count = 0
        var d = week.start
        while d < week.end {
            if isHabitDone(habit, on: d) { count += 1 }
            d = calendar.date(byAdding: .day, value: 1, to: d) ?? week.end
        }
        return count
    }

    func note(for habit: Habit, on date: Date = Date()) -> String {
        data.days[Store.key(for: date)]?.habitNotes[habit.id.uuidString] ?? ""
    }

    func setNote(_ text: String, for habit: Habit) {
        let key = todayKey
        update { d in
            var rec = d.days[key] ?? DayRecord()
            let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
            rec.habitNotes[habit.id.uuidString] = t.isEmpty ? nil : t
            d.days[key] = rec
        }
    }

    /// Notas antigas, da mais nova para a mais velha.
    func notes(for habit: Habit) -> [NoteEntry] {
        var result: [NoteEntry] = []
        for (k, rec) in data.days {
            if let text = rec.habitNotes[habit.id.uuidString] {
                result.append(NoteEntry(key: k, text: text))
            }
        }
        return result.sorted { $0.key > $1.key }
    }

    func saveHabit(_ habit: Habit) {
        update { d in
            if let i = d.habits.firstIndex(where: { $0.id == habit.id }) {
                d.habits[i] = habit
            } else {
                d.habits.append(habit)
            }
        }
        Notifications.scheduleHabit(habit)
    }

    func deleteHabit(_ habit: Habit) {
        update { d in
            d.habits.removeAll { $0.id == habit.id }
            d.conclusions[habit.id.uuidString] = nil
        }
        Notifications.cancelHabit(habit)
    }

    func conclusion(for habit: Habit) -> HabitConclusion? {
        data.conclusions[habit.id.uuidString]
    }

    func saveConclusion(_ conclusion: HabitConclusion, for habit: Habit) {
        update { $0.conclusions[habit.id.uuidString] = conclusion }
    }

    var canAddHabit: Bool { !monkActive && data.habits.count < Store.maxHabits }

    // MARK: Conquistas

    /// Confere as conquistas e guarda as novas. Na primeira vez, guarda sem festa.
    func refreshAchievements() {
        let stats = achievementStats
        let silent = !data.achievementsSeeded
        for a in Achievement.all {
            let earned = a.timesEarned(stats)
            guard earned > 0 else { continue }
            let old = data.achievements[a.id]
            let isNew = old == nil || (a.renews && earned > (old?.times ?? 0))
            guard isNew else { continue }
            data.achievements[a.id] = AchievementRecord(date: Date(), times: earned)
            if !silent && !celebrations.contains(a.id) { celebrations.append(a.id) }
        }
        if silent { data.achievementsSeeded = true }
    }

    /// Fecha a comemoração que está aberta (e passa para a próxima, se tiver).
    func finishCelebration() {
        if !celebrations.isEmpty { celebrations.removeFirst() }
    }

    // MARK: Trocas (mente)

    func logMind(_ session: MindSession) {
        update { $0.mindSessions.append(session) }
    }

    func mindSessions(on date: Date) -> [MindSession] {
        data.mindSessions.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    var swapsToday: Int { mindSessions(on: Date()).count }

    /// Trocas dos últimos 7 dias (hoje incluído).
    var mindLastWeek: [MindSession] {
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date())) ?? Date()
        return data.mindSessions.filter { $0.date >= start }
    }

    /// Quantidade de trocas em cada um dos últimos 7 dias, do mais antigo para hoje.
    var mindDailyCounts: [DayCount] {
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { back in
            let day = calendar.date(byAdding: .day, value: -back, to: today) ?? today
            return DayCount(date: day, count: mindSessions(on: day).count)
        }
    }

    func mindMinutes(_ kind: MindKind, in sessions: [MindSession]) -> Int {
        sessions.filter { $0.kind == kind }.reduce(0) { $0 + $1.seconds } / 60
    }

    func pagesRead(in sessions: [MindSession]) -> Int {
        sessions.filter { $0.kind == .ler }.reduce(0) { $0 + $1.pages }
    }

    func booksFinished(in sessions: [MindSession]) -> Int {
        sessions.filter { $0.kind == .ler && $0.finishedBook }.count
    }

    /// Trocas deste mês (para o "Seu mês").
    var mindThisMonth: [MindSession] {
        data.mindSessions.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }

    /// O último livro registrado (para não digitar de novo).
    var lastBook: String {
        data.mindSessions
            .filter { $0.kind == .ler && !$0.title.isEmpty }
            .max { $0.date < $1.date }
            .map { $0.finishedBook ? "" : $0.title } ?? ""
    }

    /// Tudo o que foi escrito, do mais novo para o mais velho.
    var journal: [MindSession] {
        data.mindSessions.filter { !$0.text.isEmpty }.sorted { $0.date > $1.date }
    }

    // MARK: Tempo de tela

    var latestScreen: ScreenTimeEntry? {
        data.screenEntries.max { $0.date < $1.date }
    }

    /// Hora de registrar a semana de novo?
    var needsScreenUpdate: Bool {
        guard let base = data.screenBaseline else { return false }
        let last = latestScreen?.date ?? base.date
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: last), to: calendar.startOfDay(for: Date())).day ?? 0
        return days >= 7
    }

    /// Quantos dias faltam para anotar a semana de novo (0 = já pode).
    var daysUntilScreenUpdate: Int {
        guard let base = data.screenBaseline else { return 0 }
        let last = latestScreen?.date ?? base.date
        return max(7 - daysBetween(last, Date()), 0)
    }

    /// Dias de 24 horas por ano, com esse tempo de tela por dia.
    static func daysPerYear(_ minutesPerDay: Int, hoursPerDay: Double = 24) -> Int {
        Int((Double(max(minutesPerDay, 0)) * 365 / (hoursPerDay * 60)).rounded())
    }

    func saveBaseline(_ entry: ScreenTimeEntry) {
        update { $0.screenBaseline = entry }
    }

    func addScreenEntry(_ entry: ScreenTimeEntry) {
        update { $0.screenEntries.append(entry) }
    }

    /// "3h40", "45 min".
    static func durationText(_ minutes: Int) -> String {
        let m = max(minutes, 0)
        if m < 60 { return "\(m) min" }
        return String(format: "%dh%02d", m / 60, m % 60)
    }

    func addFocusMinutes(_ minutes: Int) {
        guard minutes > 0 else { return }
        let key = todayKey
        update { d in
            var rec = d.days[key] ?? DayRecord()
            rec.focusMinutes += minutes
            d.days[key] = rec
        }
    }

    /// Recalcula se a rotina de hoje está completa (usado depois de editar a rotina).
    func refreshTodayCompletion() {
        let key = todayKey
        update { d in
            var rec = d.days[key] ?? DayRecord()
            let ids = Set(d.routine.map(\.id))
            rec.routineCompleted = !ids.isEmpty && ids.isSubset(of: rec.routineDone)
            d.days[key] = rec
        }
    }

    // MARK: Progresso

    /// Situação de cada dia, do dia 1 até `upTo`. Dias perdidos usam reservas (2 por semana).
    func statuses(upTo lastDay: Int) -> [DayStatus] {
        guard data.startDate != nil else { return Array(repeating: .future, count: lastDay) }
        var result: [DayStatus] = []
        var usedPerWeek: [String: Int] = [:]
        let todayNumber = dayNumber
        for day in 1...max(lastDay, 1) {
            guard let date = date(forDay: day) else { result.append(.future); continue }
            let rec = data.days[Store.key(for: date)]
            if day > todayNumber {
                result.append(.future)
            } else if rec?.routineCompleted == true {
                result.append(.done)
            } else if day == todayNumber {
                result.append(.today)
            } else {
                let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
                let week = "\(comps.yearForWeekOfYear ?? 0)-\(comps.weekOfYear ?? 0)"
                let used = usedPerWeek[week] ?? 0
                if used < Store.reservesPerWeek {
                    usedPerWeek[week] = used + 1
                    result.append(.reserve)
                } else {
                    result.append(.missed)
                }
            }
        }
        return result
    }

    /// Dias com a rotina completa (nunca zera).
    var completedDays: Int {
        data.days.values.filter { $0.routineCompleted }.count
    }

    /// Reservas que ainda sobram nesta semana.
    var reservesLeftThisWeek: Int {
        let all = statuses(upTo: dayNumber)
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        var used = 0
        for (i, s) in all.enumerated() where s == .reserve {
            if let d = date(forDay: i + 1) {
                let c = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: d)
                if c.yearForWeekOfYear == comps.yearForWeekOfYear && c.weekOfYear == comps.weekOfYear {
                    used += 1
                }
            }
        }
        return max(Store.reservesPerWeek - used, 0)
    }

    var totalFocusMinutes: Int {
        data.days.values.reduce(0) { $0 + $1.focusMinutes }
    }

    var routineTimeText: String {
        String(format: "%d:%02d", data.routineHour, data.routineMinute)
    }

    #if DEBUG
    /// Para tirar prints no simulador: abrir o app com `-demoMonk ativo`, `falha`, `fim` ou `onboarding`.
    /// Usa dados de exemplo só na memória; os dados reais do celular não mudam.
    private func seedDemo(_ mode: String) {
        isDemo = true
        if mode == "onboarding" {
            // Onboarding do zero, sem apagar os dados reais.
            data = AppData()
            return
        }
        let today = calendar.startOfDay(for: Date())
        let titles = ["Treinar", "Ler 10 páginas", "Beber 2L de água", "Sem redes antes do meio-dia", "Dormir antes da meia-noite"]
        var habits = titles.compactMap { t in Library.habits.first { $0.title == t } }
        if let i = habits.firstIndex(where: { $0.title == "Dormir antes da meia-noite" }) {
            habits[i].reminders = [HabitReminder(hour: 23, minute: 30)]
        }
        let ids = habits.map(\.id)
        let todayNumber = mode == "ativo" ? 12 : 13
        let start = calendar.date(byAdding: .day, value: -(todayNumber - 1), to: today) ?? today
        var d = data
        d.onboarded = true
        if d.startDate == nil { d.startDate = calendar.date(byAdding: .day, value: -20, to: today) }
        if d.routine.isEmpty { d.routine = Array(Library.routine.prefix(3)) }
        d.habits = habits
        for n in 1..<todayNumber {
            guard let date = calendar.date(byAdding: .day, value: n - 1, to: start) else { continue }
            let key = Store.key(for: date)
            var rec = d.days[key] ?? DayRecord()
            rec.habitsDone = Set(ids)
            if mode != "ativo" && n == todayNumber - 1 { rec.habitsDone.remove(ids[3]) }
            d.days[key] = rec
        }
        var rec = d.days[Store.key(for: today)] ?? DayRecord()
        rec.habitsDone = mode == "ativo" ? Set(ids.prefix(3)) : []
        d.days[Store.key(for: today)] = rec
        let previous = calendar.date(byAdding: .day, value: -45, to: today) ?? today
        d.monkHistory = [MonkAttempt(startDate: previous, daysCompleted: 12, end: .failed)]
        d.secondChancesUsed = []
        if mode == "fim", let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            d.secondChancesUsed = [Store.monthKey(for: yesterday)]
        }
        var run = MonkRun(startDate: start, habitIDs: ids, attempt: 2)
        if mode == "ativo", let day7 = calendar.date(byAdding: .day, value: 6, to: start) {
            // Dia 7 perdoado com a segunda chance.
            let key = Store.key(for: day7)
            d.days[key]?.habitsDone.remove(ids[4])
            run.forgivenDays = [key]
            d.secondChancesUsed = [Store.monthKey(for: day7)]
        }
        d.monk = run
        if mode == "ativo" {
            // Trocas de exemplo: hoje e no começo do mês.
            func session(_ kind: MindKind, daysAgo: Int, minutes: Int = 0, pages: Int = 0, book: String = "", finished: Bool = false) -> MindSession {
                var m = MindSession(kind: kind, seconds: minutes * 60, title: book, pages: pages, finishedBook: finished)
                m.date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
                return m
            }
            d.mindSessions = [
                session(.ler, daysAgo: 0, pages: 12, book: "O Poder do Hábito"),
                session(.pensar, daysAgo: 0, minutes: 3),
                session(.meditar, daysAgo: 1, minutes: 10),
                session(.ler, daysAgo: 2, pages: 30, book: "O Poder do Hábito"),
                session(.respirar, daysAgo: 2, minutes: 2),
                session(.ler, daysAgo: 3, pages: 58, book: "Hábitos Atômicos", finished: true),
            ]
            func task(_ id: String, daysAgo: Int, minutes: Int = 0) -> MindSession {
                var m = MindSession(kind: .outro, seconds: minutes * 60, title: Activity.find(id)?.title ?? id, activity: id)
                m.date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
                return m
            }
            d.mindSessions += [
                task("alongar", daysAgo: 0),
                task("foco", daysAgo: 0, minutes: 25),
                task("caminhar", daysAgo: 1, minutes: 15),
                task("desenhar", daysAgo: 2, minutes: 10),
                task("familia", daysAgo: 3),
            ]
        }
        // Tempo de tela de exemplo: 4h10 antes, 2h30 na última semana anotada.
        var base = ScreenTimeEntry(totalMinutes: 250, instagramMinutes: 75)
        base.date = calendar.date(byAdding: .day, value: -21, to: today) ?? today
        var week = ScreenTimeEntry(totalMinutes: 150, instagramMinutes: 40)
        week.date = calendar.date(byAdding: .day, value: -8, to: today) ?? today
        d.screenBaseline = base
        d.screenEntries = [week]
        data = d
    }
    #endif
}
