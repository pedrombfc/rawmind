import SwiftUI
import UIKit

/// Sessão de foco simples: escolhe a duração e o tempo corre.
struct FocusView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var minutes = 25
    @State private var endDate: Date? = nil
    @State private var startDate: Date? = nil
    @State private var finished = false

    private let options = [15, 25, 45, 60]

    var body: some View {
        VStack(spacing: 28) {
            HStack {
                Spacer()
                Button {
                    stop(saving: true)
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .foregroundStyle(Theme.muted)
                .accessibilityLabel("Fechar")
            }

            Spacer()

            if finished {
                VStack(spacing: 12) {
                    Text("Feito.")
                        .font(.archivo(44))
                    Text("\(minutes) minutos de foco de verdade. Levanta, bebe uma água.")
                        .font(.inter(16))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                }
            } else if let endDate {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let remaining = max(0, endDate.timeIntervalSince(context.date))
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().stroke(Theme.track, lineWidth: 6)
                            Circle()
                                .trim(from: 0, to: 1 - remaining / Double(minutes * 60))
                                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Text(clock(remaining))
                                .font(.archivo(56))
                                .monospacedDigit()
                        }
                        .frame(width: 250, height: 250)
                        Text("Celular virado pra baixo. Só isso agora.")
                            .font(.inter(15))
                            .foregroundStyle(Theme.muted)
                    }
                    .onChange(of: remaining <= 0) { _, isOver in
                        if isOver { complete() }
                    }
                }
            } else {
                VStack(spacing: 24) {
                    Text("Quanto tempo de foco?")
                        .font(.archivo(30))
                    HStack(spacing: 10) {
                        ForEach(options, id: \.self) { m in
                            Chip(label: "\(m) min", selected: minutes == m) { minutes = m }
                        }
                    }
                }
            }

            Spacer()

            if finished {
                Button("Fechar") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
            } else if endDate != nil {
                Button("Parar agora") { stop(saving: true); dismiss() }
                    .font(.inter(16, .medium))
                    .foregroundStyle(Theme.muted)
                    .frame(height: 56)
            } else {
                Button("Começar") { start() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .foregroundStyle(Theme.text)
        .screenBackground()
        .interactiveDismissDisabled(endDate != nil && !finished)
    }

    private func clock(_ seconds: TimeInterval) -> String {
        let s = Int(seconds.rounded(.up))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    private func start() {
        startDate = Date()
        endDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        Notifications.requestPermission { granted in
            if granted { Notifications.scheduleFocusEnd(after: TimeInterval(minutes * 60)) }
        }
    }

    private func complete() {
        guard !finished else { return }
        finished = true
        store.addFocusMinutes(minutes)
        startDate = nil
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func stop(saving: Bool) {
        Notifications.cancelFocus()
        if saving, !finished, let startDate {
            store.addFocusMinutes(Int(Date().timeIntervalSince(startDate) / 60))
        }
        startDate = nil
        endDate = nil
    }
}
