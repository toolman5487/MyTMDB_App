//
//  AppIntentSessionResolver.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import Foundation

// MARK: - AppIntentSessionResolutionError

nonisolated enum AppIntentSessionResolutionError: Error, Sendable, Equatable {
    case requiresUserLogin
    case invalidAccount
}

// MARK: - AppIntentSessionResolving

nonisolated protocol AppIntentSessionResolving: Sendable {
    func resolveUserAccountContext() async throws -> MemberCenterAccountContext
}

// MARK: - AppIntentSessionResolver

nonisolated struct AppIntentSessionResolver: AppIntentSessionResolving {
    private let sessionStore: any SessionStoring
    private let accountService: any AccountServiceProtocol

    init(
        sessionStore: any SessionStoring = SessionStore(),
        accountService: any AccountServiceProtocol = AccountService()
    ) {
        self.sessionStore = sessionStore
        self.accountService = accountService
    }

    func resolveUserAccountContext() async throws -> MemberCenterAccountContext {
        guard case .user(let sessionId) = sessionStore.load(),
              !sessionId.isEmpty else {
            throw AppIntentSessionResolutionError.requiresUserLogin
        }

        let account = try await accountService.fetchAccount(sessionId: sessionId)
        guard account.id > 0 else {
            throw AppIntentSessionResolutionError.invalidAccount
        }

        return MemberCenterAccountContext(
            accountId: account.id,
            sessionId: sessionId
        )
    }
}
