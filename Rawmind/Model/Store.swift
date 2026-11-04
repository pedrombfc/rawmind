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
    static let maxHabits = 5

    private(set) var data: AppData
    private let storageKey = "rawmind.data.v1"

    init() {
        if let raw = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(AppData.self, from: raw) {
            data = decoded
        } else {
            data = AppData()
        }
    }

    // MARK: Gravar

    func update(_ change: (inout AppData) -> Void) {
        change(&data)
        save()
    }

    private func save() {
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
    }

    // MARK: Monk Mode (hábitos)

    func habitDoneDays(_ habit: Habit) -> Int {
        data.days.values.filter { $0.habitsDone.contains(habit.id) }.count
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

    var canAddHabit: Bool { data.habits.count < Store.maxHabits }

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
}
