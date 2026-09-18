//
//  LogoutUseCase.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - LogoutUseCase

nonisolated enum LogoutScope: Sendable, Equatable {
    case remoteAndLocal
    case localOnly
}

nonisolated enum LogoutError: Error, Sendable, Equatable {
    case secureSessionUnavailable
    case remoteRevocationFailed
}

nonisolated protocol LogoutUseCase: Sendable {
    func callAsFunction(scope: LogoutScope) async throws
}

extension LogoutUseCase {
    func callAsFunction() async throws {
        try await callAsFunction(scope: .remoteAndLocal)
    }
}

// MARK: - DefaultLogoutUseCase

nonisolated struct DefaultLogoutUseCase: LogoutUseCase {

    // MARK: - Properties

    private let sessionProvider: AuthSessionProviding
    private let profileProvider: AccountProfileProviding
    private let authentication: AuthenticationProviding

    // MARK: - Initialization

    init(
        sessionProvider: AuthSessionProviding,
        profileProvider: AccountProfileProviding,
        authentication: AuthenticationProviding
    ) {
        self.sessionProvider = sessionProvider
        self.profileProvider = profileProvider
        self.authentication = authentication
    }

    // MARK: - LogoutUseCase

    func callAsFunction(scope: LogoutScope) async throws {
        let session: AuthSession
        do {
            session = try sessionProvider.currentSession()
        } catch {
            throw LogoutError.secureSessionUnavailable
        }

        if scope == .remoteAndLocal, case .user(let sessionID) = session {
            do {
                try await authentication.deleteUserSession(sessionID: sessionID)
            } catch let error as NetworkError where [401, 404].contains(error.statusCode ?? 0) {
                AppLogger.authentication.notice(
                    "TMDB session was already invalid during logout: \(error.statusCode ?? 0, privacy: .public)"
                )
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                AppLogger.authentication.error("TMDB session revocation failed")
                throw LogoutError.remoteRevocationFailed
            }
        }

        do {
            try sessionProvider.clearSession()
        } catch {
            throw LogoutError.secureSessionUnavailable
        }
        profileProvider.clearCachedProfile()
    }
}
