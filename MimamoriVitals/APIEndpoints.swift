//
//  APIEndpoints.swift
//  MimamoriVitals
//
//  Created by Masaaki Sakamoto on 2026/01/18.
//

import Foundation

enum APIEndpoints {
    static let vitals: URL = {
        /// フロント（バックエンド）が用意した受信 endpoint
        /// ※ここだけ差し替えればOK
        guard let url = URL(string: "https://frontend.example.com/api/v1/vitals") else {
            fatalError("Invalid API endpoint URL")
        }
        return url
    }()
}
