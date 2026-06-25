import SwiftUI

struct CycleRingView: View {
    @EnvironmentObject var session: WatchSessionManager
    @State private var animateRing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Cycle Ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 12)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: animateRing ? session.cycleData.progress : 0)
                        .stroke(
                            phaseColor(session.cycleData.phase),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: session.cycleData.progress)

                    // Center text
                    VStack(spacing: 2) {
                        Text("\(session.cycleData.currentValue)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("of \(session.cycleData.maxValue) days")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .frame(width: 120, height: 120)
                .padding(.top, 8)

                // Phase name
                Text(session.cycleData.phase)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(phaseColor(session.cycleData.phase))

                // Days until period
                if session.cycleData.daysUntilPeriod > 0 {
                    Text("\(session.cycleData.daysUntilPeriod) days until period")
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
                        Text("Log Period")
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
                    Text(session.isConnected ? "Synced" : "No connection")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Last sync time
                if let time = session.lastSyncTime {
                    Text("Updated \(time.formatted(.dateTime.hour().minute()))")
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

    func phaseColor(_ phase: String) -> Color {
        switch phase.lowercaseString {
        case "menstruation", "period", "حيض":
            return .pink
        case "follicular", "جريبية":
            return .purple
        case "ovulation", "تبويض":
            return .orange
        case "luteal", "لوتينية":
            return .blue
        default:
            return .green
        }
    }
}
