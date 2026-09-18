//
//  AuthSessionProviding.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - AuthSessionProviding

nonisolated protocol AuthSessionProviding: Sendable {
    func currentSession() throws -> AuthSession

    func clearSession() throws
}

// MARK: - AuthSessionError

nonisolated enum AuthSessionError: Error, Sendable, Equatable {
    case secureStorageUnavailable
    case invalidStoredSession
}
