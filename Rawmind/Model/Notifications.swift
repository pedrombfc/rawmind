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

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
