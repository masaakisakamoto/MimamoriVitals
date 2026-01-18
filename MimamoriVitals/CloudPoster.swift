//
//  CloudPoster.swift
//  MimamoriVitals
//
//  Created by Masaaki Sakamoto on 2026/01/18.
//

import Foundation

struct CloudPoster {

    /// バイタルJSONをフロントの endpoint に POST
    static func postVitals(_ json: [String: Any]) async {
        guard JSONSerialization.isValidJSONObject(json),
              let data = try? JSONSerialization.data(withJSONObject: json) else {
            print("[CloudPoster] invalid JSON")
            return
        }

        var request = URLRequest(url: APIEndpoints.vitals)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 🔐 認証が必要になったらここを有効化
        // request.setValue("Bearer YOUR_TOKEN", forHTTPHeaderField: "Authorization")

        request.httpBody = data

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                print("[CloudPoster] status:", http.statusCode)
            }
        } catch {
            print("[CloudPoster] error:", error.localizedDescription)
        }
    }
}
