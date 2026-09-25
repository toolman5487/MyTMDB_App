//
//  LaunchSessionResolver.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/25.
//

import Foundation

// MARK: - LaunchSessionResolutionError

nonisolated enum LaunchSessionResolutionError: Error, Sendable, Equatable {
    case invalidGuestSession
}

// MARK: - LaunchSessionResolver

nonisolated struct LaunchSessionResolver: Sendable {
    private let sessionValidator: AuthSessionValidator
    private let authentication: AuthenticationProviding
    private let sessionStore: SessionStoring
    private let userProfileStore: UserProfileStoring

    init(
        sessionValidator: AuthSessionValidator,
        authentication: AuthenticationProviding,
        sessionStore: SessionStoring,
        userProfileStore: UserProfileStoring
    ) {
        self.sessionValidator = sessionValidator
        self.authentication = authentication
        self.sessionStore = sessionStore
        self.userProfileStore = userProfileStore
    }

    func resolve() async throws -> AuthSession {
        let validatedSession = try await sessionValidator.validatedStoredSession()
        try Task.checkCancellation()

        switch validatedSession {
        case .loggedOut:
            return try await createGuestSession()

        case .guest, .user:
            return validatedSession
        }
    }

    private func createGuestSession() async throws -> AuthSession {
        let sessionID = try await authentication.createGuestSession()
        try Task.checkCancellation()
        guard !sessionID.isEmpty else {
            throw LaunchSessionResolutionError.invalidGuestSession
        }

        let session = AuthSession.guest(sessionID: sessionID)
        try sessionStore.save(session)
        userProfileStore.clear()
        return session
    }
}
