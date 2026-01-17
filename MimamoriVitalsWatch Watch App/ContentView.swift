//
//  ContentView.swift
//  MimamoriVitalsWatch Watch App
//
//  Created by Masaaki Sakamoto on 2026/01/17.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var wm = WatchSessionManager.shared
    @StateObject private var hrm = HeartRateManager.shared
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 10) {
            Text("Watch")
            Text("HR: \(Int(hrm.latestHR ?? 0))")

            Button("Ping送信") { wm.sendPing() }

            Button("心拍を取得") {
                hrm.fetchLatest()
                if let hr = hrm.latestHR {
                    wm.processHeartRate(hr: hr)
                }
            }

            Button("心拍を送信") {
                if let hr = hrm.latestHR {
                    wm.sendVitals(hr: hr)
                } else {
                    print("[UI] heart rate not ready")
                }
            }
        }
        .onAppear {
            wm.activate()
            Task { await hrm.requestAuthorization() }

            // ★ Timerはここに1個だけ
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                hrm.fetchLatest()
                if let hr = hrm.latestHR {
                    wm.processHeartRate(hr: hr) // ★安定策：値が同じでも評価される
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}
