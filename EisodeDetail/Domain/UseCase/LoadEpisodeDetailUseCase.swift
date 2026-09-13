//
//  LoadEpisodeDetailUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - LoadEpisodeDetailUseCase

nonisolated protocol LoadEpisodeDetailUseCase: Sendable {
    func callAsFunction(input: EpisodeDetailInput) async throws -> EpisodeDetailContent
}

// MARK: - DefaultLoadEpisodeDetailUseCase

nonisolated struct DefaultLoadEpisodeDetailUseCase: LoadEpisodeDetailUseCase {

    // MARK: - Properties

    private let repository: EpisodeDetailProviding
    private let accountCredential: EpisodeAccountCredential?
    private let auxiliaryFailureHandler: @Sendable (String, EpisodeDetailInput, any Error) -> Void

    // MARK: - Initialization

    init(
        repository: EpisodeDetailProviding,
        accountCredential: EpisodeAccountCredential?,
        auxiliaryFailureHandler: @escaping @Sendable (String, EpisodeDetailInput, any Error) -> Void
    ) {
        self.repository = repository
        self.accountCredential = accountCredential
        self.auxiliaryFailureHandler = auxiliaryFailureHandler
    }

    // MARK: - LoadEpisodeDetailUseCase

    func callAsFunction(input: EpisodeDetailInput) async throws -> EpisodeDetailContent {
        guard input.isValid else { throw DomainError.invalidIdentifier(.tv) }

        async let credits = optional(
            name: "episode credits",
            input: input,
            fallback: EpisodeCredits.empty(id: input.episodeNumber)
        ) {
            try await repository.credits(input: input)
        }
        async let images = optional(
            name: "episode images",
            input: input,
            fallback: EpisodeImages.empty(id: input.episodeNumber)
        ) {
            try await repository.images(input: input)
        }
        async let videos = optional(
            name: "episode videos",
            input: input,
            fallback: [Video]()
        ) {
            try await repository.videos(input: input)
        }
        async let externalIDs = optional(
            name: "episode external IDs",
            input: input,
            fallback: EpisodeExternalIDs.empty(id: input.episodeNumber)
        ) {
            try await repository.externalIDs(input: input)
        }
        async let translations = optional(
            name: "episode translations",
            input: input,
            fallback: EpisodeTranslations.empty(id: input.episodeNumber)
        ) {
            try await repository.translations(input: input)
        }
        async let accountState = loadAccountState(input: input)

        let detail = try await repository.episode(input: input)

        return await EpisodeDetailContent(
            detail: detail,
            credits: credits,
            images: images,
            videos: videos,
            externalIDs: externalIDs,
            translations: translations,
            accountState: accountState,
            supportsAccountRating: supportsAccountRating(input: input)
        )
    }

    // MARK: - Private Helpers

    private func loadAccountState(input: EpisodeDetailInput) async -> EpisodeAccountState {
        guard supportsAccountRating(input: input), let accountCredential else {
            return EpisodeAccountState.unrated(id: input.episodeNumber)
        }

        return await optional(
            name: "episode account state",
            input: input,
            fallback: EpisodeAccountState.unrated(id: input.episodeNumber)
        ) {
            try await repository.accountState(input: input, credential: accountCredential)
        }
    }

    private func supportsAccountRating(input: EpisodeDetailInput) -> Bool {
        input.seasonNumber > 0
    }

    private func optional<T: Sendable>(
        name: String,
        input: EpisodeDetailInput,
        fallback: T,
        operation: @Sendable () async throws -> T
    ) async -> T {
        do {
            return try await operation()
        } catch {
            auxiliaryFailureHandler(name, input, error)
            return fallback
        }
    }
}
