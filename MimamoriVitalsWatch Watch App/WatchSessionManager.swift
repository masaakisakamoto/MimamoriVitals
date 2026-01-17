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

    // ===== 発火ゲート設定 =====
    private let minInterval: TimeInterval = 10   // 最短10秒
    private let deltaThreshold: Double = 8       // ±8bpm

    private var lastSentAt: Date? = nil          // 前回送信時刻
    private var lastSentHR: Double? = nil        // 前回送信心拍
    private var lastQueuedHR: Double? = nil      // 送信判定用（任意）

    override private init() {
        super.init()
    }

    /// 心拍サンプルが来たらここに流す（発火ゲート）
    func processHeartRate(hr: Double) {
        let now = Date()

        // 初回：基準がないので1回送る（デモが安定する）
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
        guard let last = lastSentHR else { return }
        let delta = abs(hr - last)

        guard delta >= deltaThreshold else {
            return
        }

        // 送信確定
        lastSentAt = now
        lastSentHR = hr
        lastQueuedHR = hr

        print("[Gate] FIRE hr=\(hr) delta=\(delta)")
        sendVitals(hr: hr)
    }

    // ===== WCSession =====
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
