//
//  SeasonDetailService.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - SeasonDetailServicing

nonisolated protocol SeasonDetailServicing: Sendable {
    func fetchSeasonDetailContent(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> SeasonDetailContent

    func fetchSeasonDetail(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> SeasonDetail

    func fetchSeasonAggregateCredits(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> TVAggregateCreditsResponse

    func fetchSeasonCredits(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> SeasonCreditsResponse

    func fetchSeasonImages(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> TVImagesResponse

    func fetchSeasonVideos(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> TVVideosResponse

    func fetchSeasonWatchProviders(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> TVWatchProvidersResponse

    func fetchSeasonExternalIDs(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> SeasonExternalIDsResponse

    func fetchSeasonTranslations(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> SeasonTranslationsResponse

    func fetchSeasonAccountStates(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> SeasonAccountStatesResponse
}

// MARK: - SeasonDetailService

nonisolated final class SeasonDetailService: SeasonDetailServicing {

    // MARK: - Properties

    private let network: NetworkServicing
    private let localization: AppLocalization
    private let session: AuthSession?

    // MARK: - Initialization

    init(
        network: NetworkServicing = NetworkService(),
        localization: AppLocalization = .current,
        session: AuthSession? = nil
    ) {
        self.network = network
        self.localization = localization
        self.session = session
    }

    // MARK: - Public Methods

    func fetchSeasonDetailContent(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> SeasonDetailContent {
        async let detail = fetchSeasonDetail(seriesID: seriesID, seasonNumber: seasonNumber)
        async let aggregateCredits = fetchAuxiliaryContent(
            name: "season aggregate credits",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            fallback: TVAggregateCreditsResponse(id: seasonNumber)
        ) {
            try await fetchSeasonAggregateCredits(seriesID: seriesID, seasonNumber: seasonNumber)
        }
        async let credits = fetchAuxiliaryContent(
            name: "season credits",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            fallback: SeasonCreditsResponse(id: seasonNumber)
        ) {
            try await fetchSeasonCredits(seriesID: seriesID, seasonNumber: seasonNumber)
        }
        async let images = fetchAuxiliaryContent(
            name: "season images",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            fallback: TVImagesResponse(id: seasonNumber)
        ) {
            try await fetchSeasonImages(seriesID: seriesID, seasonNumber: seasonNumber)
        }
        async let videos = fetchAuxiliaryContent(
            name: "season videos",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            fallback: TVVideosResponse(id: seasonNumber)
        ) {
            try await fetchSeasonVideos(seriesID: seriesID, seasonNumber: seasonNumber)
        }
        async let watchProviders = fetchAuxiliaryContent(
            name: "season watch providers",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            fallback: TVWatchProvidersResponse(id: seasonNumber)
        ) {
            try await fetchSeasonWatchProviders(seriesID: seriesID, seasonNumber: seasonNumber)
        }
        async let externalIDs = fetchAuxiliaryContent(
            name: "season external IDs",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            fallback: SeasonExternalIDsResponse(id: seasonNumber)
        ) {
            try await fetchSeasonExternalIDs(seriesID: seriesID, seasonNumber: seasonNumber)
        }
        async let translations = fetchAuxiliaryContent(
            name: "season translations",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            fallback: SeasonTranslationsResponse(id: seasonNumber)
        ) {
            try await fetchSeasonTranslations(seriesID: seriesID, seasonNumber: seasonNumber)
        }
        async let accountStates = fetchAuxiliaryContent(
            name: "season account states",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            fallback: SeasonAccountStatesResponse(id: seasonNumber)
        ) {
            try await fetchSeasonAccountStates(seriesID: seriesID, seasonNumber: seasonNumber)
        }

        return try await SeasonDetailContent(
            detail: detail,
            aggregateCredits: aggregateCredits,
            credits: credits,
            images: images,
            videos: videos,
            watchProviders: watchProviders,
            externalIDs: externalIDs,
            translations: translations,
            accountStates: accountStates
        )
    }

    func fetchSeasonDetail(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> SeasonDetail {
        try await network.get(
            path: APIConfig.TV.seasonDetail(seriesId: seriesID, seasonNumber: seasonNumber),
            queryItems: localizedQueryItems
        )
    }

    func fetchSeasonAggregateCredits(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> TVAggregateCreditsResponse {
        try await network.get(
            path: APIConfig.TV.seasonAggregateCredits(seriesId: seriesID, seasonNumber: seasonNumber),
            queryItems: localizedQueryItems
        )
    }

    func fetchSeasonCredits(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> SeasonCreditsResponse {
        try await network.get(
            path: APIConfig.TV.seasonCredits(seriesId: seriesID, seasonNumber: seasonNumber),
            queryItems: localizedQueryItems
        )
    }

    func fetchSeasonImages(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> TVImagesResponse {
        try await network.get(
            path: APIConfig.TV.seasonImages(seriesId: seriesID, seasonNumber: seasonNumber),
            queryItems: imageQueryItems
        )
    }

    func fetchSeasonVideos(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> TVVideosResponse {
        try await network.get(
            path: APIConfig.TV.seasonVideos(seriesId: seriesID, seasonNumber: seasonNumber),
            queryItems: videoQueryItems
        )
    }

    func fetchSeasonWatchProviders(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> TVWatchProvidersResponse {
        try await network.get(
            path: APIConfig.TV.seasonWatchProviders(seriesId: seriesID, seasonNumber: seasonNumber),
            queryItems: []
        )
    }

    func fetchSeasonExternalIDs(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> SeasonExternalIDsResponse {
        try await network.get(
            path: APIConfig.TV.seasonExternalIds(seriesId: seriesID, seasonNumber: seasonNumber),
            queryItems: []
        )
    }

    func fetchSeasonTranslations(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> SeasonTranslationsResponse {
        try await network.get(
            path: APIConfig.TV.seasonTranslations(seriesId: seriesID, seasonNumber: seasonNumber),
            queryItems: []
        )
    }

    func fetchSeasonAccountStates(
        seriesID: Int,
        seasonNumber: Int
    ) async throws -> SeasonAccountStatesResponse {
        try await network.get(
            path: APIConfig.TV.seasonAccountStates(seriesId: seriesID, seasonNumber: seasonNumber),
            queryItems: accountStateQueryItems
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

    private var accountStateQueryItems: [URLQueryItem] {
        switch session {
        case .user(let sessionID):
            return [URLQueryItem(name: "session_id", value: sessionID)]

        case .guest(let sessionID):
            return [URLQueryItem(name: "guest_session_id", value: sessionID)]

        case .loggedOut, nil:
            return []
        }
    }

    private func fetchAuxiliaryContent<T: Sendable>(
        name: String,
        seriesID: Int,
        seasonNumber: Int,
        fallback: T,
        operation: @Sendable () async throws -> T
    ) async -> T {
        do {
            return try await operation()
        } catch {
            AppLogger.network.warning(
                "Failed to load \(name, privacy: .public) for TV series \(seriesID, privacy: .public) season \(seasonNumber, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return fallback
        }
    }
}
