import Foundation
import UserNotifications

/// Lembretes locais (funcionam sem conta Apple Developer).
enum Notifications {
    static let morningID = "rawmind.morning"
    static let focusID = "rawmind.focus"

    static func requestPermission(then done: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { done(granted) }
        }
    }

    static func scheduleMorning(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [morningID])
        let content = UNMutableNotificationContent()
        content.title = "Rotina matinal"
        content.body = "Bom dia. Antes da tela, a sua rotina."
        content.sound = .default
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: morningID, content: content, trigger: trigger))
    }

    static func scheduleFocusEnd(after seconds: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [focusID])
        guard seconds > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Sessão de foco concluída"
        content.body = "Feito. Levanta, bebe uma água, depois decide o próximo bloco."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        center.add(UNNotificationRequest(identifier: focusID, content: content, trigger: trigger))
    }

    static func cancelFocus() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [focusID])
    }

    private static func habitIDs(_ habit: Habit) -> [String] {
        let base = "rawmind.habit.\(habit.id.uuidString)"
        return [base, base + ".0", base + ".1"]
    }

    static func scheduleHabit(_ habit: Habit) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: habitIDs(habit))
        guard !habit.reminders.isEmpty else { return }
        requestPermission { granted in
            guard granted else { return }
            for (i, r) in habit.reminders.prefix(2).enumerated() {
                let content = UNMutableNotificationContent()
                content.title = habit.title
                content.body = habit.avoid ? "Você se manteve hoje? Marque no Rawmind." : "Hora do seu hábito do Monk Mode."
                content.sound = .default
                var comps = DateComponents()
                comps.hour = r.hour
                comps.minute = r.minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                center.add(UNNotificationRequest(identifier: "rawmind.habit.\(habit.id.uuidString).\(i)", content: content, trigger: trigger))
            }
        }
    }

    static func cancelHabit(_ habit: Habit) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: habitIDs(habit))
    }

    /// Aviso do prazo do Monk Mode, um por dia que ainda falta. Lista vazia apaga todos.
    static func scheduleMonkDeadlines(_ days: [(date: Date, day: Int)]) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let old = requests.map(\.identifier).filter { $0.hasPrefix("rawmind.monk.") }
            center.removePendingNotificationRequests(withIdentifiers: old)
            for item in days {
                let content = UNMutableNotificationContent()
                content.title = "Monk Mode · dia \(item.day)"
                content.body = "Ainda falta hábito pra marcar. O prazo é meia-noite."
                content.sound = .default
                let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: item.date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let id = "rawmind.monk.\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
                center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
