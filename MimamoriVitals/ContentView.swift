//
//  ContentView.swift
//  MimamoriVitals
//
//  Created by Masaaki Sakamoto on 2026/01/17.
//

import SwiftUI

import SwiftUI

struct ContentView: View {
    @StateObject private var cm = PhoneConnectivityManager.shared

    var body: some View {
        VStack(spacing: 12) {
            Text("iPhone")
            Text(cm.last.description).font(.caption)
        }
        .padding()
        .onAppear { cm.activate() }
    }
}
