//
//  SessionStore.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import Foundation

// MARK: - SessionStoring

protocol SessionStoring: Sendable {
    func load() -> AuthSession
    func save(_ session: AuthSession)
    func clear()
}

// MARK: - SessionStore

final class SessionStore: SessionStoring, @unchecked Sendable {

    // MARK: - Properties

    private let defaults: UserDefaults
    private let storageKey = "AuthSession"

    private enum LegacyKey {
        static let userSession = "TMDBSessionID"
        static let guestSession = "TMDBGuestSessionID"
        static let isGuest = "TMDBIsGuest"
    }

    // MARK: - Initialization

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - SessionStoring

    func load() -> AuthSession {
        if let data = defaults.data(forKey: storageKey),
           let session = try? JSONDecoder().decode(AuthSession.self, from: data) {
            return session
        }
        return migrateLegacySession()
    }

    func save(_ session: AuthSession) {
        switch session {
        case .loggedOut:
            clear()
            return

        case .guest, .user:
            guard let data = try? JSONEncoder().encode(session) else { return }
            defaults.set(data, forKey: storageKey)
            removeLegacyKeys()
        }
    }

    func clear() {
        defaults.removeObject(forKey: storageKey)
        removeLegacyKeys()
    }

    // MARK: - Private Methods

    private func migrateLegacySession() -> AuthSession {
        if defaults.bool(forKey: LegacyKey.isGuest),
           let guestSessionId = defaults.string(forKey: LegacyKey.guestSession),
           !guestSessionId.isEmpty {
            let session = AuthSession.guest(sessionId: guestSessionId)
            save(session)
            return session
        }

        if let userSessionId = defaults.string(forKey: LegacyKey.userSession),
           !userSessionId.isEmpty {
            let session = AuthSession.user(sessionId: userSessionId)
            save(session)
            return session
        }

        return .loggedOut
    }

    private func removeLegacyKeys() {
        defaults.removeObject(forKey: LegacyKey.userSession)
        defaults.removeObject(forKey: LegacyKey.guestSession)
        defaults.removeObject(forKey: LegacyKey.isGuest)
    }
}
