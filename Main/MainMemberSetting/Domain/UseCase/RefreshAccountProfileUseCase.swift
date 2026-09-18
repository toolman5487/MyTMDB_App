//
//  RefreshAccountProfileUseCase.swift
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
        guard case .user(let sessionID) = try sessionProvider.currentSession() else { return }
        _ = try await profileProvider.profile(sessionID: sessionID)
    }
}
