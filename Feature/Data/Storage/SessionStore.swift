//
//  SessionStore.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import Foundation
import Security

// MARK: - SessionStoring

nonisolated protocol SessionStoring: AuthSessionProviding {
    func load() throws -> AuthSession
    func save(_ session: AuthSession) throws
    func clear() throws
}

// MARK: - AuthSessionProviding

extension SessionStoring {

    func currentSession() throws -> AuthSession {
        try load()
    }

    func clearSession() throws {
        try clear()
    }
}

// MARK: - SessionCredentialStoring

nonisolated protocol SessionCredentialStoring: Sendable {
    func load() throws -> Data?
    func save(_ data: Data) throws
    func clear() throws
}

// MARK: - KeychainSessionCredentialStore

nonisolated struct KeychainSessionCredentialStore: SessionCredentialStoring {

    // MARK: - Constants

    private enum KeychainKey {
        static let service = "co.willyhsu.CineBase.auth-session"
        static let account = "tmdb-session"
    }

    // MARK: - SessionCredentialStoring

    func load() throws -> Data? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw AuthSessionError.invalidStoredSession
            }
            return data

        case errSecItemNotFound:
            return nil

        default:
            reportFailure(operation: "read", status: status)
            throw AuthSessionError.secureStorageUnavailable
        }
    }

    func save(_ data: Data) throws {
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)

        switch updateStatus {
        case errSecSuccess:
            return

        case errSecItemNotFound:
            var query = baseQuery
            attributes.forEach { key, value in
                query[key] = value
            }
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                reportFailure(operation: "add", status: addStatus)
                throw AuthSessionError.secureStorageUnavailable
            }

        default:
            reportFailure(operation: "update", status: updateStatus)
            throw AuthSessionError.secureStorageUnavailable
        }
    }

    func clear() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            reportFailure(operation: "delete", status: status)
            throw AuthSessionError.secureStorageUnavailable
        }
    }

    // MARK: - Private Properties

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainKey.service,
            kSecAttrAccount as String: KeychainKey.account,
            kSecAttrSynchronizable as String: false
        ]
    }

    // MARK: - Private Methods

    private func reportFailure(operation: String, status: OSStatus) {
        AppLogger.security.error(
            "Keychain session \(operation, privacy: .public) failed with status \(status, privacy: .public)"
        )
    }
}

// MARK: - SessionStore

nonisolated final class SessionStore: SessionStoring {

    // MARK: - Properties

    private let preferences: AppPreferencesStorage
    private let credentialStore: SessionCredentialStoring
    private let installationIDKey = "AuthSession.InstallationID.v1"

    private struct StoredAuthSessionEnvelope: Codable, Sendable, Equatable {
        let version: Int
        let installationID: UUID
        let session: AuthSession
    }

    // MARK: - Initialization

    init(
        preferences: AppPreferencesStorage = .standard,
        credentialStore: SessionCredentialStoring = KeychainSessionCredentialStore()
    ) {
        self.preferences = preferences
        self.credentialStore = credentialStore
    }

    // MARK: - SessionStoring

    func load() throws -> AuthSession {
        let installationID = preferences.performLocked { preferencesStore in
            loadOrCreateInstallationID(in: preferencesStore)
        }

        guard let data = try credentialStore.load() else { return .loggedOut }
        return try loadKeychainSession(from: data, installationID: installationID)
    }

    func save(_ session: AuthSession) throws {
        switch session {
        case .loggedOut:
            try credentialStore.clear()

        case .guest, .user:
            let installationID = preferences.performLocked { preferencesStore in
                loadOrCreateInstallationID(in: preferencesStore)
            }
            try save(
                session,
                installationID: installationID,
                to: credentialStore
            )
        }
    }

    func clear() throws {
        try credentialStore.clear()
    }

    // MARK: - Private Methods

    private func loadKeychainSession(
        from data: Data,
        installationID: UUID
    ) throws -> AuthSession {
        guard let envelope = try? JSONDecoder().decode(StoredAuthSessionEnvelope.self, from: data),
              envelope.version == 1 else {
            throw AuthSessionError.invalidStoredSession
        }

        guard envelope.installationID == installationID else {
            try credentialStore.clear()
            return .loggedOut
        }

        switch envelope.session {
        case .loggedOut:
            try credentialStore.clear()
            return .loggedOut

        case .guest, .user:
            return envelope.session
        }
    }

    private func save(
        _ session: AuthSession,
        installationID: UUID,
        to credentialStore: SessionCredentialStoring
    ) throws {
        let envelope = StoredAuthSessionEnvelope(
            version: 1,
            installationID: installationID,
            session: session
        )

        guard let data = try? JSONEncoder().encode(envelope) else {
            throw AuthSessionError.secureStorageUnavailable
        }

        try credentialStore.save(data)

        guard let savedData = try credentialStore.load(), savedData == data else {
            throw AuthSessionError.secureStorageUnavailable
        }
    }

    private func loadOrCreateInstallationID(in preferencesStore: UserDefaults) -> UUID {
        if let rawValue = preferencesStore.string(forKey: installationIDKey),
           let installationID = UUID(uuidString: rawValue) {
            return installationID
        }

        let installationID = UUID()
        preferencesStore.set(installationID.uuidString, forKey: installationIDKey)
        return installationID
    }
}
