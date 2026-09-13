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
    private let accountService: AccountServiceProtocol

    init(
        sessionStore: SessionStoring,
        accountService: AccountServiceProtocol
    ) {
        self.sessionStore = sessionStore
        self.accountService = accountService
    }

    func currentUserSession() async throws -> AccountUserSession? {
        guard case .user(let sessionID) = sessionStore.load(), !sessionID.isEmpty else {
            return nil
        }

        let account = try await accountService.fetchAccount(sessionId: sessionID)
        guard account.id > 0 else { return nil }

        return AccountUserSession(accountID: account.id, sessionID: sessionID)
    }
}
