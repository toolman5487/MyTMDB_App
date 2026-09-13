//
//  DeleteRatingUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - DeleteRatingUseCase

nonisolated protocol DeleteRatingUseCase: Sendable {
    func callAsFunction(target: AccountMediaRatingTarget) async throws -> AccountActionResult
}

// MARK: - DefaultDeleteRatingUseCase

nonisolated struct DefaultDeleteRatingUseCase: DeleteRatingUseCase {
    private let sessionRepository: AccountSessionProviding
    private let mediaRepository: AccountMediaStateProviding

    init(
        sessionRepository: AccountSessionProviding,
        mediaRepository: AccountMediaStateProviding
    ) {
        self.sessionRepository = sessionRepository
        self.mediaRepository = mediaRepository
    }

    func callAsFunction(target: AccountMediaRatingTarget) async throws -> AccountActionResult {
        guard target.isValid else { throw AccountMediaError.invalidIdentifier }
        guard let session = try await sessionRepository.currentUserSession() else {
            throw AccountMediaError.requiresUserLogin
        }

        return try await mediaRepository.deleteRating(
            sessionID: session.sessionID,
            target: target
        )
    }
}
