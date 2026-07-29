//
//  SessionStore.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import Foundation
import Synchronization

// MARK: - SessionStoring

protocol SessionStoring: Sendable {
    func load() -> AuthSession
    func save(_ session: AuthSession)
    func clear()
}

// MARK: - AppPreferencesStorage

nonisolated final class AppPreferencesStorage: Sendable {

    // MARK: - Properties

    static let standard = AppPreferencesStorage()

    private let lock = Mutex(())
    private let suiteName: String?

    // MARK: - Initialization

    init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    // MARK: - Public Methods

    func performLocked<Result>(_ work: (UserDefaults) -> Result) -> Result {
        lock.withLock { _ in
            let preferencesStore = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
            return work(preferencesStore)
        }
    }
}

// MARK: - SessionStore

final class SessionStore: SessionStoring {

    // MARK: - Properties

    private let preferences: AppPreferencesStorage
    private let storageKey = "AuthSession"

    private enum LegacyKey {
        static let userSession = "TMDBSessionID"
        static let guestSession = "TMDBGuestSessionID"
        static let isGuest = "TMDBIsGuest"
    }

    // MARK: - Initialization

    init(preferences: AppPreferencesStorage = .standard) {
        self.preferences = preferences
    }

    // MARK: - SessionStoring

    func load() -> AuthSession {
        preferences.performLocked { preferencesStore in
            load(from: preferencesStore)
        }
    }

    func save(_ session: AuthSession) {
        preferences.performLocked { preferencesStore in
            save(session, to: preferencesStore)
        }
    }

    func clear() {
        preferences.performLocked { preferencesStore in
            clear(in: preferencesStore)
        }
    }

    // MARK: - Private Methods

    private func load(from preferencesStore: UserDefaults) -> AuthSession {
        if let data = preferencesStore.data(forKey: storageKey),
           let session = try? JSONDecoder().decode(AuthSession.self, from: data) {
            return session
        }
        return migrateLegacySession(from: preferencesStore)
    }

    private func save(_ session: AuthSession, to preferencesStore: UserDefaults) {
        switch session {
        case .loggedOut:
            clear(in: preferencesStore)
            return

        case .guest, .user:
            guard let data = try? JSONEncoder().encode(session) else { return }
            preferencesStore.set(data, forKey: storageKey)
            removeLegacyKeys(from: preferencesStore)
        }
    }

    private func clear(in preferencesStore: UserDefaults) {
        preferencesStore.removeObject(forKey: storageKey)
        removeLegacyKeys(from: preferencesStore)
    }

    private func migrateLegacySession(from preferencesStore: UserDefaults) -> AuthSession {
        if preferencesStore.bool(forKey: LegacyKey.isGuest),
           let guestSessionId = preferencesStore.string(forKey: LegacyKey.guestSession),
           !guestSessionId.isEmpty {
            let session = AuthSession.guest(sessionId: guestSessionId)
            save(session, to: preferencesStore)
            return session
        }

        if let userSessionId = preferencesStore.string(forKey: LegacyKey.userSession),
           !userSessionId.isEmpty {
            let session = AuthSession.user(sessionId: userSessionId)
            save(session, to: preferencesStore)
            return session
        }

        return .loggedOut
    }

    private func removeLegacyKeys(from preferencesStore: UserDefaults) {
        preferencesStore.removeObject(forKey: LegacyKey.userSession)
        preferencesStore.removeObject(forKey: LegacyKey.guestSession)
        preferencesStore.removeObject(forKey: LegacyKey.isGuest)
    }
}
