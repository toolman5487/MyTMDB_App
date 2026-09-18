//
//  AuthFlowHandler.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/14.
//

import Foundation

// MARK: - AuthSessionValidator

nonisolated struct AuthSessionValidator: Sendable {
    private let sessionStore: SessionStoring
    private let profileProvider: AccountProfileProviding
    private let userProfileStore: UserProfileStoring

    init(
        sessionStore: SessionStoring,
        profileProvider: AccountProfileProviding,
        userProfileStore: UserProfileStoring
    ) {
        self.sessionStore = sessionStore
        self.profileProvider = profileProvider
        self.userProfileStore = userProfileStore
    }

    func validatedStoredSession() async throws -> AuthSession {
        let storedSession = try sessionStore.load()
        let validatedSession = await validatedSession(storedSession)

        if validatedSession == .loggedOut {
            try sessionStore.clear()
            userProfileStore.clear()
        } else if validatedSession != storedSession {
            try sessionStore.save(validatedSession)
        }

        return validatedSession
    }

    private func validatedSession(_ session: AuthSession) async -> AuthSession {
        switch session {
        case .loggedOut, .guest:
            return session

        case .user(let sessionID):
            return await validateUserSession(sessionID: sessionID)
        }
    }

    private func validateUserSession(sessionID: String) async -> AuthSession {
        do {
            _ = try await profileProvider.profile(sessionID: sessionID)
            return .user(sessionID: sessionID)
        } catch let error as NetworkError where [401, 403].contains(error.statusCode ?? 0) {
            AppLogger.authentication.warning(
                "Stored user session is unauthorized: \(error.statusCode ?? 0, privacy: .public)"
            )
            return .loggedOut
        } catch {
            AppLogger.authentication.error(
                "Stored user session validation failed: \(error.errorMessage.message, privacy: .public)"
            )
            return .user(sessionID: sessionID)
        }
    }
}

// MARK: - AuthFlowHandling

@MainActor
protocol AuthFlowHandling: AnyObject {
    func finishUserLogin(sessionID: String) async throws
    func finishGuestLogin(sessionID: String) async throws
}

// MARK: - AuthFlowHandler

@MainActor
final class AuthFlowHandler: AuthFlowHandling {
    private let sessionStore: SessionStoring
    private let profileProvider: AccountProfileProviding
    private let userProfileStore: UserProfileStoring
    private let onFinish: @MainActor (AuthSession) -> Void

    init(
        sessionStore: SessionStoring,
        profileProvider: AccountProfileProviding,
        userProfileStore: UserProfileStoring,
        onFinish: @escaping @MainActor (AuthSession) -> Void
    ) {
        self.sessionStore = sessionStore
        self.profileProvider = profileProvider
        self.userProfileStore = userProfileStore
        self.onFinish = onFinish
    }

    func finishUserLogin(sessionID: String) async throws {
        let session = AuthSession.user(sessionID: sessionID)
        do {
            _ = try await profileProvider.profile(sessionID: sessionID)
            try Task.checkCancellation()
            try sessionStore.save(session)
        } catch {
            userProfileStore.clear()
            throw error
        }
        onFinish(session)
    }

    func finishGuestLogin(sessionID: String) async throws {
        let session = AuthSession.guest(sessionID: sessionID)
        try sessionStore.save(session)
        userProfileStore.clear()
        onFinish(session)
    }
}
