//
//  LoadPersonCreditsUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - LoadPersonCreditsUseCase

nonisolated protocol LoadPersonCreditsUseCase: Sendable {
    func callAsFunction(
        personID: Int,
        mediaType: PersonCreditMediaType
    ) async throws -> PersonCredits
}

// MARK: - DefaultLoadPersonCreditsUseCase

nonisolated struct DefaultLoadPersonCreditsUseCase: LoadPersonCreditsUseCase {

    // MARK: - Properties

    private let repository: PersonDetailProviding

    // MARK: - Initialization

    init(repository: PersonDetailProviding) {
        self.repository = repository
    }

    // MARK: - LoadPersonCreditsUseCase

    func callAsFunction(
        personID: Int,
        mediaType: PersonCreditMediaType
    ) async throws -> PersonCredits {
        guard personID > 0 else { throw PersonDetailError.invalidIdentifier }

        switch mediaType {
        case .movie:
            return try await repository.movieCredits(personID: personID)

        case .tv:
            return try await repository.tvCredits(personID: personID)

        case .unknown:
            throw PersonDetailError.unsupportedCreditMediaType
        }
    }
}
