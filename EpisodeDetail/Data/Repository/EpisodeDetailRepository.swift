//
//  EpisodeDetailRepository.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - EpisodeDetailRepository

nonisolated final class EpisodeDetailRepository: EpisodeDetailProviding {

    // MARK: - Properties

    private let network: NetworkServicing
    private let localization: AppLocalization

    // MARK: - Initialization

    init(
        network: NetworkServicing,
        localization: AppLocalization = .current
    ) {
        self.network = network
        self.localization = localization
    }

    // MARK: - EpisodeDetailProviding

    func episode(input: EpisodeDetailInput) async throws -> Episode {
        let dto: EpisodeDetailDTO = try await network.get(
            path: APIConfig.TV.episodeDetail(
                seriesID: input.seriesID,
                seasonNumber: input.seasonNumber,
                episodeNumber: input.episodeNumber
            ),
            queryItems: localizedQueryItems
        )
        return dto.mapped()
    }

    func credits(input: EpisodeDetailInput) async throws -> EpisodeCredits {
        let dto: EpisodeCreditsDTO = try await network.get(
            path: APIConfig.TV.episodeCredits(
                seriesID: input.seriesID,
                seasonNumber: input.seasonNumber,
                episodeNumber: input.episodeNumber
            ),
            queryItems: localizedQueryItems
        )
        return dto.mapped()
    }

    func images(input: EpisodeDetailInput) async throws -> EpisodeImages {
        let dto: EpisodeImagesDTO = try await network.get(
            path: APIConfig.TV.episodeImages(
                seriesID: input.seriesID,
                seasonNumber: input.seasonNumber,
                episodeNumber: input.episodeNumber
            ),
            queryItems: imageQueryItems
        )
        return dto.mapped()
    }

    func videos(input: EpisodeDetailInput) async throws -> [Video] {
        let dto: VideosDTO = try await network.get(
            path: APIConfig.TV.episodeVideos(
                seriesID: input.seriesID,
                seasonNumber: input.seasonNumber,
                episodeNumber: input.episodeNumber
            ),
            queryItems: videoQueryItems
        )
        return dto.mapped()
    }

    func externalIDs(input: EpisodeDetailInput) async throws -> EpisodeExternalIDs {
        let dto: EpisodeExternalIDsDTO = try await network.get(
            path: APIConfig.TV.episodeExternalIDs(
                seriesID: input.seriesID,
                seasonNumber: input.seasonNumber,
                episodeNumber: input.episodeNumber
            ),
            queryItems: []
        )
        return dto.mapped()
    }

    func translations(input: EpisodeDetailInput) async throws -> EpisodeTranslations {
        let dto: EpisodeTranslationsDTO = try await network.get(
            path: APIConfig.TV.episodeTranslations(
                seriesID: input.seriesID,
                seasonNumber: input.seasonNumber,
                episodeNumber: input.episodeNumber
            ),
            queryItems: []
        )
        return dto.mapped()
    }

    func accountState(
        input: EpisodeDetailInput,
        credential: EpisodeAccountCredential
    ) async throws -> EpisodeAccountState {
        let dto: EpisodeAccountStateDTO = try await network.get(
            path: APIConfig.TV.episodeAccountStates(
                seriesID: input.seriesID,
                seasonNumber: input.seasonNumber,
                episodeNumber: input.episodeNumber
            ),
            queryItems: accountStateQueryItems(credential: credential)
        )
        return dto.mapped()
    }

    // MARK: - Private Helpers

    private var localizedQueryItems: [URLQueryItem] {
        [URLQueryItem(name: "language", value: localization.languageParameter)]
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

    private func accountStateQueryItems(
        credential: EpisodeAccountCredential
    ) -> [URLQueryItem] {
        switch credential {
        case .guest(let sessionID):
            return [URLQueryItem(name: "guest_session_id", value: sessionID)]

        case .user(let sessionID):
            return [URLQueryItem(name: "session_id", value: sessionID)]
        }
    }
}
