//
//  WatchSessionManager.swift
//  MimamoriVitalsWatch Watch App
//
//  Created by Masaaki Sakamoto on 2026/01/18.
//

import Foundation
import WatchConnectivity
import Combine

@MainActor
final class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()

    override private init() { super.init() }

    func activate() {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        s.delegate = self
        s.activate()
        print("[Watch] activate")
    }

    func sendPing() {
        let s = WCSession.default
        print("[Watch] isReachable =", s.isReachable)

        let msg: [String: Any] = [
            "type": "ping",
            "ts": Date().timeIntervalSince1970
        ]

        if s.isReachable {
            print("[Watch] sendMessage")
            s.sendMessage(msg, replyHandler: nil) { error in
                print("[Watch] sendMessage error:", error.localizedDescription)
            }
        } else {
            print("[Watch] transferUserInfo")
            s.transferUserInfo(msg)
        }
    }
    
    func sendVitals(
        hr: Double,
        userId: String = "demo-elderly-001"
    ) {
        let s = WCSession.default

        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")

        let msg: [String: Any] = [
            "user_id": userId,
            "timestamp": formatter.string(from: Date()),
            "watch": [
                "hr_bpm": Int(hr.rounded()),   // 実測
                "hr_confidence": 0.9,          // 仮値（未実装）
                "hrv_rmssd_ms": 28,            // 仮値（未実装）
                "motion_energy": 0.63,         // 仮値（未実装）
                "steps_per_min": 0,            // 仮値（未実装）
                "is_wrist_on": true,           // 仮値（未実装）
                "battery": 0.54                // 仮値（未実装）
            ]
        ]

        print("[Watch] sendVitals payload:", msg)
        print("[Watch] isReachable =", s.isReachable)

        if s.isReachable {
            s.sendMessage(msg, replyHandler: { reply in
                print("[Watch] sendVitals reply:", reply)
            }, errorHandler: { error in
                print("[Watch] sendVitals error:", error.localizedDescription)
            })
        } else {
            s.transferUserInfo(msg)
            print("[Watch] vital -> transferUserInfo (queued)")
        }
    }
}

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        print("[Watch] activated:", activationState.rawValue, "error:", error?.localizedDescription ?? "nil")
    }
}
