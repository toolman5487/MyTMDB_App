//
//  EpisodeDetailService.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/8.
//

import Foundation

// MARK: - EpisodeDetailServicing

nonisolated protocol EpisodeDetailServicing: Sendable {
    func fetchEpisodeDetailContent(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async throws -> EpisodeDetailContent

    func fetchEpisodeDetail(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async throws -> EpisodeDetail

    func fetchEpisodeCredits(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async throws -> EpisodeCreditsResponse

    func fetchEpisodeImages(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async throws -> EpisodeImagesResponse

    func fetchEpisodeVideos(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async throws -> TVVideosResponse

    func fetchEpisodeExternalIDs(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async throws -> EpisodeExternalIDsResponse

    func fetchEpisodeTranslations(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async throws -> EpisodeTranslationsResponse

    func fetchEpisodeAccountStates(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async throws -> EpisodeAccountStatesResponse
}

// MARK: - EpisodeDetailService

nonisolated final class EpisodeDetailService: EpisodeDetailServicing {

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

    func fetchEpisodeDetailContent(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async throws -> EpisodeDetailContent {
        async let detail = fetchEpisodeDetail(
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber
        )
        async let credits = fetchAuxiliaryContent(
            name: "episode credits",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            fallback: EpisodeCreditsResponse(id: episodeNumber)
        ) {
            try await fetchEpisodeCredits(
                seriesID: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            )
        }
        async let images = fetchAuxiliaryContent(
            name: "episode images",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            fallback: EpisodeImagesResponse(id: episodeNumber)
        ) {
            try await fetchEpisodeImages(
                seriesID: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            )
        }
        async let videos = fetchAuxiliaryContent(
            name: "episode videos",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            fallback: TVVideosResponse(id: episodeNumber)
        ) {
            try await fetchEpisodeVideos(
                seriesID: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            )
        }
        async let externalIDs = fetchAuxiliaryContent(
            name: "episode external IDs",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            fallback: EpisodeExternalIDsResponse(id: episodeNumber)
        ) {
            try await fetchEpisodeExternalIDs(
                seriesID: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            )
        }
        async let translations = fetchAuxiliaryContent(
            name: "episode translations",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            fallback: EpisodeTranslationsResponse(id: episodeNumber)
        ) {
            try await fetchEpisodeTranslations(
                seriesID: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            )
        }
        async let accountStates = fetchEpisodeAccountStatesIfSupported(
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber
        )

        return try await EpisodeDetailContent(
            detail: detail,
            credits: credits,
            images: images,
            videos: videos,
            externalIDs: externalIDs,
            translations: translations,
            accountStates: accountStates,
            supportsAccountRating: supportsAccountRating(seasonNumber: seasonNumber)
        )
    }

    func fetchEpisodeDetail(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async throws -> EpisodeDetail {
        try await network.get(
            path: APIConfig.TV.episodeDetail(
                seriesId: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            ),
            queryItems: localizedQueryItems
        )
    }

    func fetchEpisodeCredits(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async throws -> EpisodeCreditsResponse {
        try await network.get(
            path: APIConfig.TV.episodeCredits(
                seriesId: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            ),
            queryItems: localizedQueryItems
        )
    }

    func fetchEpisodeImages(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async throws -> EpisodeImagesResponse {
        try await network.get(
            path: APIConfig.TV.episodeImages(
                seriesId: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            ),
            queryItems: imageQueryItems
        )
    }

    func fetchEpisodeVideos(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async throws -> TVVideosResponse {
        try await network.get(
            path: APIConfig.TV.episodeVideos(
                seriesId: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            ),
            queryItems: videoQueryItems
        )
    }

    func fetchEpisodeExternalIDs(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async throws -> EpisodeExternalIDsResponse {
        try await network.get(
            path: APIConfig.TV.episodeExternalIds(
                seriesId: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            ),
            queryItems: []
        )
    }

    func fetchEpisodeTranslations(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async throws -> EpisodeTranslationsResponse {
        try await network.get(
            path: APIConfig.TV.episodeTranslations(
                seriesId: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            ),
            queryItems: []
        )
    }

    func fetchEpisodeAccountStates(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async throws -> EpisodeAccountStatesResponse {
        try await network.get(
            path: APIConfig.TV.episodeAccountStates(
                seriesId: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            ),
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

    private func fetchEpisodeAccountStatesIfSupported(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async -> EpisodeAccountStatesResponse {
        guard supportsAccountRating(seasonNumber: seasonNumber) else {
            return EpisodeAccountStatesResponse(id: episodeNumber)
        }

        return await fetchAuxiliaryContent(
            name: "episode account states",
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            fallback: EpisodeAccountStatesResponse(id: episodeNumber)
        ) {
            try await fetchEpisodeAccountStates(
                seriesID: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            )
        }
    }

    private func supportsAccountRating(seasonNumber: Int) -> Bool {
        seasonNumber > 0
    }

    private func fetchAuxiliaryContent<T: Sendable>(
        name: String,
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int,
        fallback: T,
        operation: @Sendable () async throws -> T
    ) async -> T {
        do {
            return try await operation()
        } catch {
            AppLogger.network.warning(
                "Failed to load \(name, privacy: .public) for TV series \(seriesID, privacy: .public) season \(seasonNumber, privacy: .public) episode \(episodeNumber, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return fallback
        }
    }
}
