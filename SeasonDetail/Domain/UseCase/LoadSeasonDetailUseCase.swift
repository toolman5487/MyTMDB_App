//
//  LoadSeasonDetailUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - LoadSeasonDetailUseCase

nonisolated protocol LoadSeasonDetailUseCase: Sendable {
    func callAsFunction(seriesID: Int, seasonNumber: Int) async throws -> SeasonDetailContent
}

// MARK: - DefaultLoadSeasonDetailUseCase

nonisolated struct DefaultLoadSeasonDetailUseCase: LoadSeasonDetailUseCase {

    // MARK: - Properties

    private let repository: SeasonDetailProviding
    private let accountCredential: SeasonAccountCredential?
    private let auxiliaryFailureHandler: @Sendable (String, Int, Int, any Error) -> Void

    // MARK: - Initialization

    init(
        repository: SeasonDetailProviding,
        accountCredential: SeasonAccountCredential?,
        auxiliaryFailureHandler: @escaping @Sendable (String, Int, Int, any Error) -> Void
    ) {
        self.repository = repository
        self.accountCredential = accountCredential
        self.auxiliaryFailureHandler = auxiliaryFailureHandler
    }

    // MARK: - LoadSeasonDetailUseCase

    func callAsFunction(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> SeasonDetailContent {
        guard seriesID > 0, seasonNumber >= 0 else {
            throw DomainError.invalidIdentifier(.tv)
        }

        async let aggregateCredits = optional(
            name: "season aggregate credits",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            fallback: AggregateCredits.empty
        ) {
            try await repository.aggregateCredits(seriesID: seriesID, seasonNumber: seasonNumber)
        }
        async let credits = optional(
            name: "season credits",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            fallback: SeasonCredits.empty(id: seasonNumber)
        ) {
            try await repository.credits(seriesID: seriesID, seasonNumber: seasonNumber)
        }
        async let images = optional(
            name: "season images",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            fallback: MediaImages.empty
        ) {
            try await repository.images(seriesID: seriesID, seasonNumber: seasonNumber)
        }
        async let videos = optional(
            name: "season videos",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            fallback: [Video]()
        ) {
            try await repository.videos(seriesID: seriesID, seasonNumber: seasonNumber)
        }
        async let watchProviders = optional(
            name: "season watch providers",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            fallback: WatchProviders.empty
        ) {
            try await repository.watchProviders(seriesID: seriesID, seasonNumber: seasonNumber)
        }
        async let externalIDs = optional(
            name: "season external IDs",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            fallback: SeasonExternalIDs.empty(id: seasonNumber)
        ) {
            try await repository.externalIDs(seriesID: seriesID, seasonNumber: seasonNumber)
        }
        async let translations = optional(
            name: "season translations",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            fallback: SeasonTranslations.empty(id: seasonNumber)
        ) {
            try await repository.translations(seriesID: seriesID, seasonNumber: seasonNumber)
        }
        async let accountState = loadAccountState(seriesID: seriesID, seasonNumber: seasonNumber)

        let detail = try await repository.season(seriesID: seriesID, seasonNumber: seasonNumber)

        return await SeasonDetailContent(
            detail: detail,
            aggregateCredits: aggregateCredits,
            credits: credits,
            images: images,
            videos: videos,
            watchProviders: watchProviders,
            externalIDs: externalIDs,
            translations: translations,
            accountState: accountState
        )
    }

    // MARK: - Private Helpers

    private func loadAccountState(
        seriesID: Int,
        seasonNumber: Int
    ) async -> SeasonAccountState {
        guard let accountCredential else {
            return SeasonAccountState.unrated(id: seasonNumber)
        }

        return await optional(
            name: "season account state",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            fallback: SeasonAccountState.unrated(id: seasonNumber)
        ) {
            try await repository.accountState(
                seriesID: seriesID,
                seasonNumber: seasonNumber,
                credential: accountCredential
            )
        }
    }

    private func optional<T: Sendable>(
        name: String,
        seriesID: Int,
        seasonNumber: Int,
        fallback: T,
        operation: @Sendable () async throws -> T
    ) async -> T {
        do {
            return try await operation()
        } catch {
            auxiliaryFailureHandler(name, seriesID, seasonNumber, error)
            return fallback
        }
    }
}
