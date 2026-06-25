import SwiftUI

struct CycleRingView: View {
    @EnvironmentObject var session: WatchSessionManager
    @State private var animateRing = false

    @Environment(\.locale) private var locale

    private var isArabic: Bool {
        locale.language.languageCode?.identifier == "ar"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Cycle Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: animateRing ? session.cycleData.progress : 0)
                        .stroke(
                            phaseColor(session.cycleData.phase),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: session.cycleData.progress)

                    VStack(spacing: 2) {
                        Text("\(session.cycleData.currentValue)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(daysText)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .frame(width: 120, height: 120)
                .padding(.top, 8)

                // Phase name
                Text(phaseText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(phaseColor(session.cycleData.phase))

                // Days until period
                if session.cycleData.daysUntilPeriod > 0 {
                    Text(daysUntilText)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Log Period button
                Button(action: {
                    session.sendLogRequest()
                }) {
                    HStack {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 12))
                        Text(logPeriodText)
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.pink)
                    .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())

                // Connection status
                HStack(spacing: 4) {
                    Circle()
                        .fill(session.isConnected ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                    Text(session.isConnected ? syncedText : noConnectionText)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.6))
                }

                if let time = session.lastSyncTime {
                    Text(time.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Lune")
        .onAppear {
            animateRing = true
        }
    }

    // MARK: - Localized Strings

    private var daysText: String {
        let current = session.cycleData.currentValue
        let max = session.cycleData.maxValue
        return isArabic ? "\(current) من \(max) يوم" : "\(current) of \(max) days"
    }

    private var phaseText: String {
        let phase = session.cycleData.phase
        if isArabic {
            switch phase.lowercased() {
            case "menstruation", "period": return "حيض"
            case "follicular": return "جريبية"
            case "ovulation": return "تبويض"
            case "luteal": return "لوتينية"
            default: return phase
            }
        }
        return phase
    }

    private var daysUntilText: String {
        let days = session.cycleData.daysUntilPeriod
        return isArabic ? "\(days) يوم حتى الدورة" : "\(days) days until period"
    }

    private var logPeriodText: String {
        isArabic ? "تسجيل الدورة" : "Log Period"
    }

    private var syncedText: String {
        isArabic ? "متزامن" : "Synced"
    }

    private var noConnectionText: String {
        isArabic ? "لا يوجد اتصال" : "No connection"
    }

    // MARK: - Helpers

    func phaseColor(_ phase: String) -> Color {
        switch phase.lowercased() {
        case "menstruation", "period", "حيض": return .pink
        case "follicular", "جريبية": return .purple
        case "ovulation", "تبويض": return .orange
        case "luteal", "لوتينية": return .blue
        default: return .green
        }
    }
}
