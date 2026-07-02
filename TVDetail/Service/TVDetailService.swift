//
//  TVDetailService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation

// MARK: - Protocol

nonisolated protocol TVDetailServicing: Sendable {
    func fetchTVDetailContent(seriesID: Int, recommendationPage: Int) async throws -> TVDetailContent

    func fetchTVDetail(seriesID: Int) async throws -> TVDetail

    func fetchTVAggregateCredits(seriesID: Int) async throws -> TVAggregateCreditsResponse

    func fetchTVVideos(seriesID: Int) async throws -> TVVideosResponse

    func fetchTVImages(seriesID: Int) async throws -> TVImagesResponse

    func fetchTVRecommendations(seriesID: Int, page: Int) async throws -> TVRecommendationsPage

    func fetchTVWatchProviders(seriesID: Int) async throws -> TVWatchProvidersResponse
}

extension TVDetailServicing {

    func fetchTVDetailContent(seriesID: Int) async throws -> TVDetailContent {
        try await fetchTVDetailContent(seriesID: seriesID, recommendationPage: 1)
    }

    func fetchTVRecommendations(seriesID: Int) async throws -> TVRecommendationsPage {
        try await fetchTVRecommendations(seriesID: seriesID, page: 1)
    }
}

// MARK: - TVDetailService

nonisolated final class TVDetailService: TVDetailServicing {

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

    func fetchTVDetailContent(
        seriesID: Int,
        recommendationPage: Int = 1
    ) async throws -> TVDetailContent {
        async let detail = fetchTVDetail(seriesID: seriesID)
        async let aggregateCredits = fetchAuxiliaryContent(
            name: "TV aggregate credits",
            seriesID: seriesID,
            fallback: TVAggregateCreditsResponse(id: seriesID)
        ) {
            try await fetchTVAggregateCredits(seriesID: seriesID)
        }
        async let videos = fetchAuxiliaryContent(
            name: "TV videos",
            seriesID: seriesID,
            fallback: TVVideosResponse(id: seriesID)
        ) {
            try await fetchTVVideos(seriesID: seriesID)
        }
        async let images = fetchAuxiliaryContent(
            name: "TV images",
            seriesID: seriesID,
            fallback: TVImagesResponse(id: seriesID)
        ) {
            try await fetchTVImages(seriesID: seriesID)
        }
        async let recommendations = fetchAuxiliaryContent(
            name: "TV recommendations",
            seriesID: seriesID,
            fallback: TVRecommendationsPage(page: recommendationPage)
        ) {
            try await fetchTVRecommendations(seriesID: seriesID, page: recommendationPage)
        }
        async let watchProviders = fetchAuxiliaryContent(
            name: "TV watch providers",
            seriesID: seriesID,
            fallback: TVWatchProvidersResponse(id: seriesID)
        ) {
            try await fetchTVWatchProviders(seriesID: seriesID)
        }

        return try await TVDetailContent(
            detail: detail,
            aggregateCredits: aggregateCredits,
            videos: videos,
            images: images,
            recommendations: recommendations,
            watchProviders: watchProviders
        )
    }

    func fetchTVDetail(seriesID: Int) async throws -> TVDetail {
        try await network.get(
            path: APIConfig.TV.detail(seriesId: seriesID),
            queryItems: localizedQueryItems
        )
    }

    func fetchTVAggregateCredits(seriesID: Int) async throws -> TVAggregateCreditsResponse {
        try await network.get(
            path: APIConfig.TV.aggregateCredits(seriesId: seriesID),
            queryItems: localizedQueryItems
        )
    }

    func fetchTVVideos(seriesID: Int) async throws -> TVVideosResponse {
        try await network.get(
            path: APIConfig.TV.videos(seriesId: seriesID),
            queryItems: videoQueryItems
        )
    }

    func fetchTVImages(seriesID: Int) async throws -> TVImagesResponse {
        try await network.get(
            path: APIConfig.TV.images(seriesId: seriesID),
            queryItems: imageQueryItems
        )
    }

    func fetchTVRecommendations(
        seriesID: Int,
        page: Int = 1
    ) async throws -> TVRecommendationsPage {
        try await network.get(
            path: APIConfig.TV.recommendations(seriesId: seriesID),
            queryItems: pagedQueryItems(page: page)
        )
    }

    func fetchTVWatchProviders(seriesID: Int) async throws -> TVWatchProvidersResponse {
        try await network.get(
            path: APIConfig.TV.watchProviders(seriesId: seriesID),
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

    private var videoQueryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: localization.languageParameter),
            URLQueryItem(name: "include_video_language", value: localization.imageLanguageParameter)
        ]
    }

    private func pagedQueryItems(page: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: localization.languageParameter),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ]
    }

    private func fetchAuxiliaryContent<T: Sendable>(
        name: String,
        seriesID: Int,
        fallback: T,
        operation: @Sendable () async throws -> T
    ) async -> T {
        do {
            return try await operation()
        } catch {
            AppLogger.network.warning(
                "Failed to load \(name, privacy: .public) for TV series \(seriesID, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return fallback
        }
    }
}
