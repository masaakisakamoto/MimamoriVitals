//
//  HeartRateManager.swift
//  MimamoriVitalsWatch Watch App
//
//  Created by Masaaki Sakamoto on 2026/01/18.
//

import Foundation
import HealthKit
import Combine

@MainActor
final class HeartRateManager: ObservableObject {
    static let shared = HeartRateManager()

    private let store = HKHealthStore()

    @Published var latestHR: Double? = nil

    private init() {}

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("[HR] Health data not available")
            return
        }
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        do {
            try await store.requestAuthorization(toShare: [], read: [hrType])
            print("[HR] authorization requested")
        } catch {
            print("[HR] auth error:", error.localizedDescription)
        }
    }

    func fetchLatest() {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        let pred = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-60 * 60),
                                              end: nil,
                                              options: .strictEndDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let q = HKSampleQuery(sampleType: hrType, predicate: pred, limit: 1, sortDescriptors: [sort]) { [weak self] _, samples, error in
            if let error = error {
                print("[HR] query error:", error.localizedDescription)
                return
            }
            guard let s = samples?.first as? HKQuantitySample else {
                print("[HR] no samples")
                return
            }

            let unit = HKUnit.count().unitDivided(by: .minute())
            let bpm = s.quantity.doubleValue(for: unit)

            Task { @MainActor in
                self?.latestHR = bpm
                print("[HR] bpm:", bpm)
            }
        }

        store.execute(q)
    }
}
