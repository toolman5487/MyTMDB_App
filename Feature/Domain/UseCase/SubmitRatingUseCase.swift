//
//  SubmitRatingUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - SubmitRatingUseCase

nonisolated protocol SubmitRatingUseCase: Sendable {
    func callAsFunction(
        target: AccountMediaRatingTarget,
        value: Double
    ) async throws -> AccountActionResult
}

// MARK: - DefaultSubmitRatingUseCase

nonisolated struct DefaultSubmitRatingUseCase: SubmitRatingUseCase {
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
        target: AccountMediaRatingTarget,
        value: Double
    ) async throws -> AccountActionResult {
        guard target.isValid else { throw AccountMediaError.invalidIdentifier }

        let normalizedValue = AccountMediaRatingValue.normalized(value)
        guard AccountMediaRatingValue.isValid(normalizedValue) else {
            throw AccountMediaError.invalidRatingValue
        }
        guard let session = try await sessionRepository.currentUserSession() else {
            throw AccountMediaError.requiresUserLogin
        }

        return try await mediaRepository.submitRating(
            sessionID: session.sessionID,
            target: target,
            value: normalizedValue
        )
    }
}
