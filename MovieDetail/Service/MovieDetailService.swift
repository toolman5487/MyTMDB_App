//
//  MovieDetailService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import Foundation

// MARK: - Protocol

nonisolated protocol MovieDetailServicing {
    func fetchMovieDetailContent(id: Int, recommendationPage: Int) async throws -> MovieDetailContent

    func fetchMovieDetail(id: Int) async throws -> MovieDetail

    func fetchMovieCredits(id: Int) async throws -> MovieCreditsResponse

    func fetchMovieVideos(id: Int) async throws -> MovieVideosResponse

    func fetchMovieImages(id: Int) async throws -> MovieImagesResponse

    func fetchMovieRecommendations(id: Int, page: Int) async throws -> MovieRecommendationsPage

    func fetchMovieWatchProviders(id: Int) async throws -> MovieWatchProvidersResponse
}

extension MovieDetailServicing {

    func fetchMovieDetailContent(id: Int) async throws -> MovieDetailContent {
        try await fetchMovieDetailContent(id: id, recommendationPage: 1)
    }

    func fetchMovieRecommendations(id: Int) async throws -> MovieRecommendationsPage {
        try await fetchMovieRecommendations(id: id, page: 1)
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
        async let credits = fetchMovieCredits(id: id)
        async let videos = fetchMovieVideos(id: id)
        async let images = fetchMovieImages(id: id)
        async let recommendations = fetchMovieRecommendations(id: id, page: recommendationPage)
        async let watchProviders = fetchMovieWatchProviders(id: id)

        return try await MovieDetailContent(
            detail: detail,
            credits: credits,
            videos: videos,
            images: images,
            recommendations: recommendations,
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

    func fetchMovieRecommendations(
        id: Int,
        page: Int = 1
    ) async throws -> MovieRecommendationsPage {
        try await network.get(
            path: APIConfig.Movie.recommendations(id: id),
            queryItems: pagedQueryItems(page: page)
        )
    }

    func fetchMovieWatchProviders(id: Int) async throws -> MovieWatchProvidersResponse {
        try await network.get(
            path: APIConfig.Movie.watchProviders(id: id),
            queryItems: []
        )
    }

    // MARK: - Private Methods

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
}
