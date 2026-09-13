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

    /// 完整清單頁會替整頁片單補海報，與首頁預覽只補前 10 筆不同。
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
