//
//  ToggleFavoriteUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - ToggleFavoriteUseCase

nonisolated protocol ToggleFavoriteUseCase: Sendable {
    func callAsFunction(
        kind: MediaKind,
        mediaID: Int,
        isFavorite: Bool
    ) async throws -> AccountActionResult
}

// MARK: - DefaultToggleFavoriteUseCase

nonisolated struct DefaultToggleFavoriteUseCase: ToggleFavoriteUseCase {
    private let sessionRepository: AccountSessionProviding
    private let mediaRepository: AccountMediaStateProviding

    init(
        sessionRepository: AccountSessionProviding,
        mediaRepository: AccountMediaStateProviding
    ) {
        self.sessionRepository = sessionRepository
        self.mediaRepository = mediaRepository
    }

    func callAsFunction(
        kind: MediaKind,
        mediaID: Int,
        isFavorite: Bool
    ) async throws -> AccountActionResult {
        guard mediaID > 0 else { throw AccountMediaError.invalidIdentifier }
        guard let session = try await sessionRepository.currentUserSession() else {
            throw AccountMediaError.requiresUserLogin
        }

        return try await mediaRepository.updateFavorite(
            accountID: session.accountID,
            sessionID: session.sessionID,
            kind: kind,
            mediaID: mediaID,
            isFavorite: isFavorite
        )
    }
}
