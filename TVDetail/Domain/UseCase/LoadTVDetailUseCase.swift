//
//  LoadTVDetailUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - LoadTVDetailUseCase

nonisolated protocol LoadTVDetailUseCase: Sendable {
    func callAsFunction(seriesID: Int, recommendationPage: Int) async throws -> TVDetailContent
}

extension LoadTVDetailUseCase {

    func callAsFunction(seriesID: Int) async throws -> TVDetailContent {
        try await callAsFunction(seriesID: seriesID, recommendationPage: 1)
    }
}

// MARK: - DefaultLoadTVDetailUseCase

nonisolated struct DefaultLoadTVDetailUseCase: LoadTVDetailUseCase {

    // MARK: - Properties

    private let repository: TVDetailProviding
    private let auxiliaryFailureHandler: @Sendable (String, Int, any Error) -> Void

    // MARK: - Initialization

    init(
        repository: TVDetailProviding,
        auxiliaryFailureHandler: @escaping @Sendable (String, Int, any Error) -> Void
    ) {
        self.repository = repository
        self.auxiliaryFailureHandler = auxiliaryFailureHandler
    }

    // MARK: - LoadTVDetailUseCase

    func callAsFunction(
        seriesID: Int,
        recommendationPage: Int = 1
    ) async throws -> TVDetailContent {
        guard seriesID > 0 else { throw DomainError.invalidIdentifier(.tv) }

        async let aggregateCredits = optional(
            name: "TV aggregate credits",
            seriesID: seriesID,
            fallback: AggregateCredits.empty
        ) {
            try await repository.aggregateCredits(seriesID: seriesID)
        }
        async let videos = optional(name: "TV videos", seriesID: seriesID, fallback: [Video]()) {
            try await repository.videos(seriesID: seriesID)
        }
        async let images = optional(name: "TV images", seriesID: seriesID, fallback: MediaImages.empty) {
            try await repository.images(seriesID: seriesID)
        }
        async let recommendations = optional(
            name: "TV recommendations",
            seriesID: seriesID,
            fallback: Page<MediaSummary>.empty(number: recommendationPage)
        ) {
            try await repository.recommendations(seriesID: seriesID, page: recommendationPage)
        }
        async let similar = optional(
            name: "TV similar",
            seriesID: seriesID,
            fallback: Page<MediaSummary>.empty(number: recommendationPage)
        ) {
            try await repository.similar(seriesID: seriesID, page: recommendationPage)
        }
        async let watchProviders = optional(
            name: "TV watch providers",
            seriesID: seriesID,
            fallback: WatchProviders.empty
        ) {
            try await repository.watchProviders(seriesID: seriesID)
        }

        let series = try await repository.series(id: seriesID)

        return await TVDetailContent(
            series: series,
            aggregateCredits: aggregateCredits,
            videos: videos,
            images: images,
            recommendations: recommendations,
            similar: similar,
            watchProviders: watchProviders
        )
    }

    // MARK: - Private Helpers

    private func optional<T: Sendable>(
        name: String,
        seriesID: Int,
        fallback: T,
        operation: @Sendable () async throws -> T
    ) async -> T {
        do {
            return try await operation()
        } catch {
            auxiliaryFailureHandler(name, seriesID, error)
            return fallback
        }
    }
}
