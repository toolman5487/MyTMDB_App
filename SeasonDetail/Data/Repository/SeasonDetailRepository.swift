//
//  SeasonDetailRepository.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - SeasonDetailRepository

nonisolated final class SeasonDetailRepository: SeasonDetailProviding {

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

    // MARK: - SeasonDetailProviding

    func season(seriesID: Int, seasonNumber: Int) async throws -> Season {
        let dto: SeasonDetailDTO = try await network.get(
            path: APIConfig.TV.seasonDetail(seriesID: seriesID, seasonNumber: seasonNumber),
            queryItems: localizedQueryItems
        )
        return dto.mapped()
    }

    func aggregateCredits(seriesID: Int, seasonNumber: Int) async throws -> AggregateCredits {
        let dto: AggregateCreditsDTO = try await network.get(
            path: APIConfig.TV.seasonAggregateCredits(seriesID: seriesID, seasonNumber: seasonNumber),
            queryItems: localizedQueryItems
        )
        return dto.mapped()
    }

    func credits(seriesID: Int, seasonNumber: Int) async throws -> SeasonCredits {
        let dto: SeasonCreditsDTO = try await network.get(
            path: APIConfig.TV.seasonCredits(seriesID: seriesID, seasonNumber: seasonNumber),
            queryItems: localizedQueryItems
        )
        return dto.mapped()
    }

    func images(seriesID: Int, seasonNumber: Int) async throws -> MediaImages {
        let dto: MediaImagesDTO = try await network.get(
            path: APIConfig.TV.seasonImages(seriesID: seriesID, seasonNumber: seasonNumber),
            queryItems: imageQueryItems
        )
        return dto.mapped()
    }

    func videos(seriesID: Int, seasonNumber: Int) async throws -> [Video] {
        let dto: VideosDTO = try await network.get(
            path: APIConfig.TV.seasonVideos(seriesID: seriesID, seasonNumber: seasonNumber),
            queryItems: videoQueryItems
        )
        return dto.mapped()
    }

    func watchProviders(seriesID: Int, seasonNumber: Int) async throws -> WatchProviders {
        let dto: WatchProvidersDTO = try await network.get(
            path: APIConfig.TV.seasonWatchProviders(seriesID: seriesID, seasonNumber: seasonNumber),
            queryItems: []
        )
        return dto.mapped()
    }

    func externalIDs(seriesID: Int, seasonNumber: Int) async throws -> SeasonExternalIDs {
        let dto: SeasonExternalIDsDTO = try await network.get(
            path: APIConfig.TV.seasonExternalIDs(seriesID: seriesID, seasonNumber: seasonNumber),
            queryItems: []
        )
        return dto.mapped()
    }

    func translations(seriesID: Int, seasonNumber: Int) async throws -> SeasonTranslations {
        let dto: SeasonTranslationsDTO = try await network.get(
            path: APIConfig.TV.seasonTranslations(seriesID: seriesID, seasonNumber: seasonNumber),
            queryItems: []
        )
        return dto.mapped()
    }

    func accountState(
        seriesID: Int,
        seasonNumber: Int,
        credential: SeasonAccountCredential
    ) async throws -> SeasonAccountState {
        let dto: SeasonAccountStateDTO = try await network.get(
            path: APIConfig.TV.seasonAccountStates(seriesID: seriesID, seasonNumber: seasonNumber),
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
        credential: SeasonAccountCredential
    ) -> [URLQueryItem] {
        switch credential {
        case .guest(let sessionID):
            return [URLQueryItem(name: "guest_session_id", value: sessionID)]

        case .user(let sessionID):
            return [URLQueryItem(name: "session_id", value: sessionID)]
        }
    }
}
