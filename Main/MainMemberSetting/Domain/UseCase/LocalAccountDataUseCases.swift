//
//  LocalAccountDataUseCases.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - RefreshAccountProfileUseCase

nonisolated protocol RefreshAccountProfileUseCase: Sendable {
    func callAsFunction() async throws
}

// MARK: - DefaultRefreshAccountProfileUseCase

nonisolated struct DefaultRefreshAccountProfileUseCase: RefreshAccountProfileUseCase {

    // MARK: - Properties

    private let sessionProvider: AuthSessionProviding
    private let profileProvider: AccountProfileProviding

    // MARK: - Initialization

    init(
        sessionProvider: AuthSessionProviding,
        profileProvider: AccountProfileProviding
    ) {
        self.sessionProvider = sessionProvider
        self.profileProvider = profileProvider
    }

    // MARK: - RefreshAccountProfileUseCase

    func callAsFunction() async throws {
        guard case .user(let sessionID) = sessionProvider.currentSession() else { return }
        _ = try await profileProvider.profile(sessionID: sessionID)
    }
}

// MARK: - LogoutUseCase

nonisolated protocol LogoutUseCase: Sendable {
    func callAsFunction()
}

// MARK: - DefaultLogoutUseCase

nonisolated struct DefaultLogoutUseCase: LogoutUseCase {

    // MARK: - Properties

    private let sessionProvider: AuthSessionProviding
    private let profileProvider: AccountProfileProviding

    // MARK: - Initialization

    init(
        sessionProvider: AuthSessionProviding,
        profileProvider: AccountProfileProviding
    ) {
        self.sessionProvider = sessionProvider
        self.profileProvider = profileProvider
    }

    // MARK: - LogoutUseCase

    func callAsFunction() {
        sessionProvider.clearSession()
        profileProvider.clearCachedProfile()
    }
}

// MARK: - ClearLocalDataUseCase

nonisolated protocol ClearLocalDataUseCase: Sendable {
    func callAsFunction()
}

// MARK: - DefaultClearLocalDataUseCase

nonisolated struct DefaultClearLocalDataUseCase: ClearLocalDataUseCase {

    // MARK: - Properties

    private let logout: LogoutUseCase
    private let searchHistory: SearchHistoryProviding

    // MARK: - Initialization

    init(
        logout: LogoutUseCase,
        searchHistory: SearchHistoryProviding
    ) {
        self.logout = logout
        self.searchHistory = searchHistory
    }

    // MARK: - ClearLocalDataUseCase

    func callAsFunction() {
        logout()
        searchHistory.clear(scope: nil)
    }
}
