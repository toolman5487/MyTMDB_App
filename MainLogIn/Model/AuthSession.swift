//
//  AuthSession.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import Foundation

// MARK: - Auth Session

enum AuthSession: Equatable, Codable, Sendable {
    case loggedOut
    case guest(sessionId: String)
    case user(sessionId: String)
}

// MARK: - AuthSession Helpers

extension AuthSession {

    var sessionId: String? {
        switch self {
        case .loggedOut:
            return nil
        case .guest(let sessionId), .user(let sessionId):
            return sessionId
        }
    }

    var isGuest: Bool {
        if case .guest = self { return true }
        return false
    }

    var isLoggedIn: Bool {
        switch self {
        case .loggedOut:
            return false
        case .guest, .user:
            return true
        }
    }
}
