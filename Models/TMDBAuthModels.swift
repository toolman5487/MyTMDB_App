//
//  TMDBAuthModels.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import Foundation

struct TokenResponse: Decodable {
    let request_token: String
    let success: Bool
}

struct ValidateResponse: Decodable {
    let success: Bool
}

struct SessionResponse: Decodable {
    let session_id: String
    let success: Bool
}
