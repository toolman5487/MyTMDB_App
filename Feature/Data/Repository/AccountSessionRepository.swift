//
//  AccountSessionRepository.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - AccountSessionRepository

nonisolated final class AccountSessionRepository: AccountSessionProviding {
    private let sessionStore: SessionStoring
    private let profileProvider: AccountProfileProviding

    init(
        sessionStore: SessionStoring,
        profileProvider: AccountProfileProviding
    ) {
        self.sessionStore = sessionStore
        self.profileProvider = profileProvider
    }

    func currentUserSession() async throws -> AccountUserSession? {
        guard case .user(let sessionID) = try sessionStore.load(), !sessionID.isEmpty else {
            return nil
        }

        if let cachedAccountID = profileProvider.cachedProfile()?.id, cachedAccountID > 0 {
            return AccountUserSession(accountID: cachedAccountID, sessionID: sessionID)
        }

        let profile = try await profileProvider.profile(sessionID: sessionID)
        guard profile.id > 0 else { return nil }

        return AccountUserSession(accountID: profile.id, sessionID: sessionID)
    }
}
