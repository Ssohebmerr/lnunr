import Foundation
import WatchConnectivity
import Combine

struct CycleData: Codable {
    var currentValue: Int = 0
    var maxValue: Int = 28
    var phase: String = "Unknown"
    var daysUntilPeriod: Int = 0

    var progress: Double {
        guard maxValue > 0 else { return 0 }
        return Double(currentValue) / Double(maxValue)
    }
}

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var cycleData = CycleData()
    @Published var isConnected = false
    @Published var lastSyncTime: Date?

    private var session: WCSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func sendLogRequest() {
        guard let session = session, session.isReachable else {
            print("Phone not reachable")
            return
        }

        let context: [String: Any] = [
            "logRequest": [
                "timestamp": Int(Date().timeIntervalSince1970 * 1000)
            ]
        ]

        do {
            try session.updateApplicationContext(context)
            print("Log request sent from watch")
        } catch {
            print("Failed to send log request: \(error)")
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
        }
        print("Watch session activated: \(activationState.rawValue)")

        // Load existing application context
        if let context = session.receivedApplicationContext as? [String: Any] {
            self.processContext(context)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.processContext(applicationContext)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.processContext(message)
        }
    }

    private func processContext(_ context: [String: Any]) {
        if let circleDict = context["circleData"] as? [String: Any] {
            cycleData.currentValue = circleDict["currentValue"] as? Int ?? 0
            cycleData.maxValue = (circleDict["maxValue"] as? Int)?.clamped(to: 1...45) ?? 28

            if let phase = circleDict["phase"] as? String {
                cycleData.phase = phase
            }
            if let days = circleDict["daysUntilPeriod"] as? Int {
                cycleData.daysUntilPeriod = days
            }

            lastSyncTime = Date()
            print("Watch received cycle data: day \(cycleData.currentValue)/\(cycleData.maxValue), phase: \(cycleData.phase)")
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
