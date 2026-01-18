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

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        print(
            "[Phone] activated:",
            activationState.rawValue,
            "error:",
            error?.localizedDescription ?? "nil"
        )
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any]
    ) {
        print("[Phone] didReceiveMessage:", message)

        Task { @MainActor in
            self.last = message
            await CloudPoster.postVitals(message)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String : Any] = [:]
    ) {
        print("[Phone] didReceiveUserInfo:", userInfo)

        Task { @MainActor in
            self.last = userInfo
            await CloudPoster.postVitals(userInfo)
        }
    }
}
