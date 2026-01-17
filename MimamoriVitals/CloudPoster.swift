//
//  CloudPoster.swift
//  MimamoriVitals
//
//  Created by Masaaki Sakamoto on 2026/01/18.
//

import Foundation

enum CloudPoster {
    static func postJSON(_ payload: [String: Any], to urlString: String) async {
        guard let url = URL(string: urlString) else {
            print("[POST] invalid url")
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
            let (data, resp) = try await URLSession.shared.data(for: req)

            if let http = resp as? HTTPURLResponse {
                print("[POST] status:", http.statusCode)
            } else {
                print("[POST] non-http response")
            }

            if let text = String(data: data, encoding: .utf8) {
                print("[POST] body:", text)
            }
        } catch {
            print("[POST] error:", error.localizedDescription)
        }
    }
}
