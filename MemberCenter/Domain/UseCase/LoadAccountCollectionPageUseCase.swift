//
//  LoadAccountCollectionPageUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - LoadAccountCollectionPageUseCase

nonisolated protocol LoadAccountCollectionPageUseCase: Sendable {
    func callAsFunction(
        destination: MemberCenterDestination,
        accountID: Int,
        sessionID: String,
        page: Int
    ) async throws -> AccountCollection
}

// MARK: - DefaultLoadAccountCollectionPageUseCase

nonisolated struct DefaultLoadAccountCollectionPageUseCase: LoadAccountCollectionPageUseCase {

    // MARK: - Properties

    private let repository: AccountContentProviding

    // MARK: - Initialization

    init(repository: AccountContentProviding) {
        self.repository = repository
    }

    // MARK: - LoadAccountCollectionPageUseCase

    func callAsFunction(
        destination: MemberCenterDestination,
        accountID: Int,
        sessionID: String,
        page: Int
    ) async throws -> AccountCollection {
        try await repository.collection(
            destination: destination,
            accountID: accountID,
            sessionID: sessionID,
            page: page,
            posterFallbackLimit: .max
        )
    }
}
