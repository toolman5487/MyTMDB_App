//
//  TMDBAuthModels.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import Foundation

struct TokenResponse: Codable {
    let request_token: String
    let success: Bool
}

struct ValidateResponse: Codable {
    let success: Bool
}

struct SessionResponse: Codable {
    let session_id: String
    let success: Bool
}
