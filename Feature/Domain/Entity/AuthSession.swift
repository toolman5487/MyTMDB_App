//
//  AuthSession.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import Foundation

// MARK: - Auth Session

nonisolated enum AuthSession: Equatable, Codable, Sendable {
    case loggedOut
    case guest(sessionID: String)
    case user(sessionID: String)

    private enum CodingKeys: String, CodingKey {
        case loggedOut
        case guest
        case user
    }

    private enum SessionCodingKeys: String, CodingKey {
        case legacySessionID = "sessionId"
        case sessionID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.contains(.loggedOut) {
            self = .loggedOut
            return
        }

        if container.contains(.guest) {
            self = .guest(
                sessionID: try Self.decodeSessionID(from: container, forKey: .guest)
            )
            return
        }

        if container.contains(.user) {
            self = .user(
                sessionID: try Self.decodeSessionID(from: container, forKey: .user)
            )
            return
        }

        throw DecodingError.typeMismatch(
            AuthSession.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unrecognized AuthSession payload."
            )
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .loggedOut:
            _ = container.nestedContainer(
                keyedBy: SessionCodingKeys.self,
                forKey: .loggedOut
            )

        case .guest(let sessionID):
            var sessionContainer = container.nestedContainer(
                keyedBy: SessionCodingKeys.self,
                forKey: .guest
            )
            try sessionContainer.encode(sessionID, forKey: .legacySessionID)

        case .user(let sessionID):
            var sessionContainer = container.nestedContainer(
                keyedBy: SessionCodingKeys.self,
                forKey: .user
            )
            try sessionContainer.encode(sessionID, forKey: .legacySessionID)
        }
    }

    private static func decodeSessionID(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> String {
        let sessionContainer = try container.nestedContainer(
            keyedBy: SessionCodingKeys.self,
            forKey: key
        )

        if let sessionID = try sessionContainer.decodeIfPresent(
            String.self,
            forKey: .legacySessionID
        ) {
            return sessionID
        }

        return try sessionContainer.decode(String.self, forKey: .sessionID)
    }
}

// MARK: - AuthSession Helpers

extension AuthSession {

    var sessionID: String? {
        switch self {
        case .loggedOut:
            return nil
        case .guest(let sessionID), .user(let sessionID):
            return sessionID
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
