//
//  LoadMovieDetailUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - LoadMovieDetailUseCase

nonisolated protocol LoadMovieDetailUseCase: Sendable {
    func callAsFunction(movieID: Int, recommendationPage: Int) async throws -> MovieDetailContent
}

extension LoadMovieDetailUseCase {

    func callAsFunction(movieID: Int) async throws -> MovieDetailContent {
        try await callAsFunction(movieID: movieID, recommendationPage: 1)
    }
}

// MARK: - DefaultLoadMovieDetailUseCase

nonisolated struct DefaultLoadMovieDetailUseCase: LoadMovieDetailUseCase {

    // MARK: - Properties

    private let repository: MovieDetailProviding
    private let failureReporter: AuxiliaryLoadFailureReporting

    // MARK: - Initialization

    init(
        repository: MovieDetailProviding,
        failureReporter: AuxiliaryLoadFailureReporting
    ) {
        self.repository = repository
        self.failureReporter = failureReporter
    }

    // MARK: - LoadMovieDetailUseCase

    func callAsFunction(
        movieID: Int,
        recommendationPage: Int = 1
    ) async throws -> MovieDetailContent {
        guard movieID > 0 else { throw DomainError.invalidIdentifier(.movie) }

        async let credits = optional(name: "movie credits", movieID: movieID, fallback: MovieCredits.empty) {
            try await repository.credits(movieID: movieID)
        }
        async let videos = optional(name: "movie videos", movieID: movieID, fallback: [Video]()) {
            try await repository.videos(movieID: movieID)
        }
        async let images = optional(name: "movie images", movieID: movieID, fallback: MediaImages.empty) {
            try await repository.images(movieID: movieID)
        }
        async let recommendations = optional(
            name: "movie recommendations",
            movieID: movieID,
            fallback: Page<MediaSummary>.empty(number: recommendationPage)
        ) {
            try await repository.recommendations(movieID: movieID, page: recommendationPage)
        }
        async let similar = optional(
            name: "movie similar",
            movieID: movieID,
            fallback: Page<MediaSummary>.empty(number: recommendationPage)
        ) {
            try await repository.similar(movieID: movieID, page: recommendationPage)
        }
        async let watchProviders = optional(
            name: "movie watch providers",
            movieID: movieID,
            fallback: WatchProviders.empty
        ) {
            try await repository.watchProviders(movieID: movieID)
        }

        let movie = try await repository.movie(id: movieID)
        let collection = await loadedCollection(for: movie)

        return await MovieDetailContent(
            movie: movie,
            credits: credits,
            videos: videos,
            images: images,
            collection: collection,
            recommendations: recommendations,
            similar: similar,
            watchProviders: watchProviders
        )
    }

    // MARK: - Private Helpers

    private func loadedCollection(for movie: Movie) async -> MovieCollection? {
        guard let collectionID = movie.collectionID else { return nil }

        return await optional(
            name: "movie collection",
            movieID: movie.id,
            fallback: nil as MovieCollection?
        ) {
            try await repository.collection(id: collectionID)
        }
    }

    private func optional<T: Sendable>(
        name: String,
        movieID: Int,
        fallback: T,
        operation: @Sendable () async throws -> T
    ) async -> T {
        do {
            return try await operation()
        } catch {
            failureReporter.reportAuxiliaryFailure(name, target: "movie \(movieID)", error: error)
            return fallback
        }
    }
}
