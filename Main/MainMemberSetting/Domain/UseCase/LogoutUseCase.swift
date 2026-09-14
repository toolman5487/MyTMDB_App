//
//  LogoutUseCase.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

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
