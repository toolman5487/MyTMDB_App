//
//  AuthenticationDTO.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - RequestTokenDTO

nonisolated struct RequestTokenDTO: Decodable, Sendable {
    let requestToken: String
    let success: Bool

    enum CodingKeys: String, CodingKey {
        case requestToken = "request_token"
        case success
    }
}

// MARK: - TokenValidationDTO

nonisolated struct TokenValidationDTO: Decodable, Sendable {
    let success: Bool
}

// MARK: - UserSessionDTO

nonisolated struct UserSessionDTO: Decodable, Sendable {
    let sessionID: String
    let success: Bool

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case success
    }
}

// MARK: - GuestSessionDTO

nonisolated struct GuestSessionDTO: Decodable, Sendable {
    let guestSessionID: String
    let success: Bool

    enum CodingKeys: String, CodingKey {
        case guestSessionID = "guest_session_id"
        case success
    }
}

// MARK: - TokenValidationRequestDTO

nonisolated struct TokenValidationRequestDTO: Encodable, Sendable {
    let username: String
    let password: String
    let requestToken: String

    enum CodingKeys: String, CodingKey {
        case username
        case password
        case requestToken = "request_token"
    }
}

// MARK: - UserSessionRequestDTO

nonisolated struct UserSessionRequestDTO: Encodable, Sendable {
    let requestToken: String

    enum CodingKeys: String, CodingKey {
        case requestToken = "request_token"
    }
}
