//
//  PhoneConnectivityManager.swift
//  MimamoriVitals
//
//  Created by Masaaki Sakamoto on 2026/01/17.
//

import Foundation
import WatchConnectivity
import Combine

@MainActor
final class PhoneConnectivityManager: NSObject, ObservableObject {
    static let shared = PhoneConnectivityManager()

    @Published var last: [String: Any] = [:]

    override private init() { super.init() }

    func activate() {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        s.delegate = self
        s.activate()
        print("[Phone] activate")
    }
}

extension PhoneConnectivityManager: WCSessionDelegate {

    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        print("[Phone] activated:", activationState.rawValue, "error:", error?.localizedDescription ?? "nil")
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    // ✅ Watchが sendMessage(replyHandler:) を使っても受けられる版（おすすめ）
    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String : Any],
                             replyHandler: @escaping ([String : Any]) -> Void) {
        print("[Phone] didReceiveMessage(reply):", message)

        replyHandler([
            "ok": true,
            "receivedAt": Date().timeIntervalSince1970
        ])

        Task { @MainActor in
            self.last = message
            let url = "https://webhook.site/68fc9121-143b-4ea0-8f83-03b5cf65a31e"
            await CloudPoster.postJSON(message, to: url)
        }
    }

    // ✅ 返信不要な sendMessage(msg) でも受けられる版（今まで通り）
    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String : Any]) {
        print("[Phone] didReceiveMessage:", message)

        Task { @MainActor in
            self.last = message
            let url = "https://webhook.site/68fc9121-143b-4ea0-8f83-03b5cf65a31e"
            await CloudPoster.postJSON(message, to: url)
        }
    }

    // ✅ transferUserInfo を受ける版（シグネチャ修正が重要）
    nonisolated func session(_ session: WCSession,
                             didReceiveUserInfo userInfo: [String : Any]) {
        print("[Phone] didReceiveUserInfo:", userInfo)

        Task { @MainActor in
            self.last = userInfo
            let url = "https://webhook.site/68fc9121-143b-4ea0-8f83-03b5cf65a31e"
            await CloudPoster.postJSON(userInfo, to: url)
        }
    }
}
