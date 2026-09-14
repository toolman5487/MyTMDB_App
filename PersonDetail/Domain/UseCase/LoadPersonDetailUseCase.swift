//
//  LoadPersonDetailUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - LoadPersonDetailUseCase

nonisolated protocol LoadPersonDetailUseCase: Sendable {
    func callAsFunction(personID: Int) async throws -> PersonDetailContent
}

// MARK: - DefaultLoadPersonDetailUseCase

nonisolated struct DefaultLoadPersonDetailUseCase: LoadPersonDetailUseCase {

    // MARK: - Properties

    private let repository: PersonDetailProviding
    private let failureReporter: AuxiliaryLoadFailureReporting

    // MARK: - Initialization

    init(
        repository: PersonDetailProviding,
        failureReporter: AuxiliaryLoadFailureReporting
    ) {
        self.repository = repository
        self.failureReporter = failureReporter
    }

    // MARK: - LoadPersonDetailUseCase

    func callAsFunction(personID: Int) async throws -> PersonDetailContent {
        guard personID > 0 else { throw PersonDetailError.invalidIdentifier }

        async let combinedCredits = optional(
            name: "person combined credits",
            personID: personID,
            fallback: PersonCredits.empty(id: personID)
        ) {
            try await repository.combinedCredits(personID: personID)
        }
        async let images = optional(
            name: "person images",
            personID: personID,
            fallback: PersonImages.empty(id: personID)
        ) {
            try await repository.images(personID: personID)
        }
        async let externalIDs = optional(
            name: "person external IDs",
            personID: personID,
            fallback: PersonExternalIDs.empty(id: personID)
        ) {
            try await repository.externalIDs(personID: personID)
        }

        let detail = try await repository.person(id: personID)

        return await PersonDetailContent(
            detail: detail,
            combinedCredits: combinedCredits,
            images: images,
            externalIDs: externalIDs
        )
    }

    // MARK: - Private Helpers

    private func optional<T: Sendable>(
        name: String,
        personID: Int,
        fallback: T,
        operation: @Sendable () async throws -> T
    ) async -> T {
        do {
            return try await operation()
        } catch {
            failureReporter.reportAuxiliaryFailure(name, target: "person \(personID)", error: error)
            return fallback
        }
    }
}
