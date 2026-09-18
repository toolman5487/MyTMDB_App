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
    private let profileProvider: any AccountProfileProviding

    init(
        sessionStore: any SessionStoring,
        profileProvider: any AccountProfileProviding
    ) {
        self.sessionStore = sessionStore
        self.profileProvider = profileProvider
    }

    func resolveUserAccountContext() async throws -> MemberCenterAccountContext {
        guard case .user(let sessionID) = try sessionStore.load(),
              !sessionID.isEmpty else {
            throw AppIntentSessionResolutionError.requiresUserLogin
        }

        if let cachedAccountID = profileProvider.cachedProfile()?.id, cachedAccountID > 0 {
            return MemberCenterAccountContext(
                accountID: cachedAccountID,
                sessionID: sessionID
            )
        }

        let profile = try await profileProvider.profile(sessionID: sessionID)
        guard profile.id > 0 else {
            throw AppIntentSessionResolutionError.invalidAccount
        }

        return MemberCenterAccountContext(
            accountID: profile.id,
            sessionID: sessionID
        )
    }
}
