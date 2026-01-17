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

    // ③ 変化量トリガ（±8bpm）＋最短10秒
    private let minInterval: TimeInterval = 10
    private let deltaThreshold: Double = 8
    private var lastSentAt: Date? = nil
    private var lastSentHR: Double? = nil

    /// 心拍サンプルが来たらここに流す（発火ゲート）
    func processHeartRate(hr: Double) {
        let now = Date()

        // 初回：基準がないので1回送る
        if lastSentAt == nil || lastSentHR == nil {
            lastSentAt = now
            lastSentHR = hr
            print("[Gate] first send hr=\(hr)")
            sendVitals(hr: hr)
            return
        }

        // 連発防止：前回送信から10秒未満なら送らない
        if let lastAt = lastSentAt, now.timeIntervalSince(lastAt) < minInterval {
            return
        }

        // 変化量判定：前回送信HRとの差が±8以上なら送る
        let delta = abs(hr - (lastSentHR ?? hr))
        guard delta >= deltaThreshold else { return }

        // 送信確定
        lastSentAt = now
        lastSentHR = hr
        print("[Gate] FIRE hr=\(hr) delta=\(delta)")
        sendVitals(hr: hr)
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        s.delegate = self
        s.activate()
        print("[Watch] activate")
    }

    func sendPing() {
        let s = WCSession.default
        let msg: [String: Any] = [
            "type": "ping",
            "ts": Date().timeIntervalSince1970
        ]

        print("[Watch] isReachable =", s.isReachable)
        if s.isReachable {
            s.sendMessage(msg, replyHandler: nil) { error in
                print("[Watch] sendPing error:", error.localizedDescription)
            }
        } else {
            s.transferUserInfo(msg)
            print("[Watch] ping -> transferUserInfo")
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
                "hr_bpm": Int(hr.rounded()),
                "hr_confidence": 0.9,
                "hrv_rmssd_ms": 28,
                "motion_energy": 0.63,
                "steps_per_min": 0,
                "is_wrist_on": true,
                "battery": 0.54
            ]
        ]

        print("[Watch] sendVitals payload:", msg)
        print("[Watch] isReachable =", s.isReachable)

        if s.isReachable {
            s.sendMessage(msg, replyHandler: nil) { error in
                print("[Watch] sendVitals error:", error.localizedDescription)
            }
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
