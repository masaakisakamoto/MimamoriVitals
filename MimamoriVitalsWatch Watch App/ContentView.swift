//
//  ContentView.swift
//  MimamoriVitalsWatch Watch App
//
//  Created by Masaaki Sakamoto on 2026/01/17.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var wm = WatchSessionManager.shared
    @StateObject private var hr = HeartRateManager.shared

    var body: some View {
        VStack(spacing: 10) {
            Text("Watch")

            Button("Ping送信") {
                wm.sendPing()
            }

            Button("心拍を取得") {
                hr.fetchLatest()
            }

            Button("心拍を送信") {
                guard let bpm = hr.latestHR else {
                    print("[UI] heart rate not ready")
                    return
                }
                wm.sendVitals(hr: bpm)
            }
        }
        .onAppear {
            wm.activate()
            Task { await hr.requestAuthorization() }
        }
    }
}
