//
//  MovieDetailService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import Foundation

// MARK: - Protocol

nonisolated protocol MovieDetailServicing: Sendable {
    func fetchMovieDetailContent(id: Int, recommendationPage: Int) async throws -> MovieDetailContent

    func fetchMovieDetail(id: Int) async throws -> MovieDetail

    func fetchMovieCredits(id: Int) async throws -> MovieCreditsResponse

    func fetchMovieVideos(id: Int) async throws -> MovieVideosResponse

    func fetchMovieImages(id: Int) async throws -> MovieImagesResponse

    func fetchMovieCollectionDetail(id: Int) async throws -> MovieCollectionDetail

    func fetchMovieRecommendations(id: Int, page: Int) async throws -> MovieRecommendationsPage

    func fetchMovieSimilar(id: Int, page: Int) async throws -> MovieSimilarPage

    func fetchMovieWatchProviders(id: Int) async throws -> MovieWatchProvidersResponse

    func fetchMovieAccountStates(id: Int, sessionId: String) async throws -> AccountMediaStatesResponse
}

extension MovieDetailServicing {

    func fetchMovieDetailContent(id: Int) async throws -> MovieDetailContent {
        try await fetchMovieDetailContent(id: id, recommendationPage: 1)
    }

    func fetchMovieRecommendations(id: Int) async throws -> MovieRecommendationsPage {
        try await fetchMovieRecommendations(id: id, page: 1)
    }

    func fetchMovieSimilar(id: Int) async throws -> MovieSimilarPage {
        try await fetchMovieSimilar(id: id, page: 1)
    }
}

// MARK: - MovieDetailService

nonisolated final class MovieDetailService: MovieDetailServicing {

    // MARK: - Properties

    private let network: NetworkServicing
    private let localization: AppLocalization

    // MARK: - Initialization

    init(
        network: NetworkServicing = NetworkService(),
        localization: AppLocalization = .current
    ) {
        self.network = network
        self.localization = localization
    }

    // MARK: - Public Methods

    func fetchMovieDetailContent(
        id: Int,
        recommendationPage: Int = 1
    ) async throws -> MovieDetailContent {
        async let detail = fetchMovieDetail(id: id)
        async let credits = fetchAuxiliaryContent(
            name: "movie credits",
            id: id,
            fallback: MovieCreditsResponse(id: id)
        ) {
            try await fetchMovieCredits(id: id)
        }
        async let videos = fetchAuxiliaryContent(
            name: "movie videos",
            id: id,
            fallback: MovieVideosResponse(id: id)
        ) {
            try await fetchMovieVideos(id: id)
        }
        async let images = fetchAuxiliaryContent(
            name: "movie images",
            id: id,
            fallback: MovieImagesResponse(id: id)
        ) {
            try await fetchMovieImages(id: id)
        }
        async let recommendations = fetchAuxiliaryContent(
            name: "movie recommendations",
            id: id,
            fallback: MovieRecommendationsPage(page: recommendationPage)
        ) {
            try await fetchMovieRecommendations(id: id, page: recommendationPage)
        }
        async let similar = fetchAuxiliaryContent(
            name: "movie similar",
            id: id,
            fallback: MovieSimilarPage(page: recommendationPage)
        ) {
            try await fetchMovieSimilar(id: id, page: recommendationPage)
        }
        async let watchProviders = fetchAuxiliaryContent(
            name: "movie watch providers",
            id: id,
            fallback: MovieWatchProvidersResponse(id: id)
        ) {
            try await fetchMovieWatchProviders(id: id)
        }

        let loadedDetail = try await detail
        let collection = await fetchMovieCollectionDetail(for: loadedDetail)

        return await MovieDetailContent(
            detail: loadedDetail,
            credits: credits,
            videos: videos,
            images: images,
            collection: collection,
            recommendations: recommendations,
            similar: similar,
            watchProviders: watchProviders
        )
    }

    func fetchMovieDetail(id: Int) async throws -> MovieDetail {
        try await network.get(
            path: APIConfig.Movie.detail(id: id),
            queryItems: localizedQueryItems
        )
    }

    func fetchMovieCredits(id: Int) async throws -> MovieCreditsResponse {
        try await network.get(
            path: APIConfig.Movie.credits(id: id),
            queryItems: []
        )
    }

    func fetchMovieVideos(id: Int) async throws -> MovieVideosResponse {
        try await network.get(
            path: APIConfig.Movie.videos(id: id),
            queryItems: localizedQueryItems
        )
    }

    func fetchMovieImages(id: Int) async throws -> MovieImagesResponse {
        try await network.get(
            path: APIConfig.Movie.images(id: id),
            queryItems: imageQueryItems
        )
    }

    func fetchMovieCollectionDetail(id: Int) async throws -> MovieCollectionDetail {
        try await network.get(
            path: APIConfig.Collection.detail(id: id),
            queryItems: localizedQueryItems
        )
    }

    func fetchMovieRecommendations(
        id: Int,
        page: Int = 1
    ) async throws -> MovieRecommendationsPage {
        try await network.get(
            path: APIConfig.Movie.recommendations(id: id),
            queryItems: pagedQueryItems(page: page)
        )
    }

    func fetchMovieSimilar(
        id: Int,
        page: Int = 1
    ) async throws -> MovieSimilarPage {
        try await network.get(
            path: APIConfig.Movie.similar(id: id),
            queryItems: pagedQueryItems(page: page)
        )
    }

    func fetchMovieWatchProviders(id: Int) async throws -> MovieWatchProvidersResponse {
        try await network.get(
            path: APIConfig.Movie.watchProviders(id: id),
            queryItems: []
        )
    }

    func fetchMovieAccountStates(id: Int, sessionId: String) async throws -> AccountMediaStatesResponse {
        try await network.get(
            path: APIConfig.Movie.accountStates(id: id),
            queryItems: authenticatedQueryItems(sessionId: sessionId)
        )
    }

    // MARK: - Private Methods

    private func authenticatedQueryItems(sessionId: String) -> [URLQueryItem] {
        [
            URLQueryItem(name: "session_id", value: sessionId)
        ]
    }

    private var localizedQueryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: localization.languageParameter)
        ]
    }

    private var imageQueryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: localization.languageParameter),
            URLQueryItem(name: "include_image_language", value: localization.imageLanguageParameter)
        ]
    }

    private func pagedQueryItems(page: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: localization.languageParameter),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ]
    }

    private func fetchMovieCollectionDetail(for detail: MovieDetail) async -> MovieCollectionDetail? {
        guard let collectionID = detail.belongsToCollection?.id else { return nil }

        return await fetchAuxiliaryContent(
            name: "movie collection",
            id: detail.id,
            fallback: nil as MovieCollectionDetail?
        ) {
            try await fetchMovieCollectionDetail(id: collectionID)
        }
    }

    private func fetchAuxiliaryContent<T: Sendable>(
        name: String,
        id: Int,
        fallback: T,
        operation: @Sendable () async throws -> T
    ) async -> T {
        do {
            return try await operation()
        } catch {
            AppLogger.network.warning(
                "Failed to load \(name, privacy: .public) for movie \(id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return fallback
        }
    }
}
