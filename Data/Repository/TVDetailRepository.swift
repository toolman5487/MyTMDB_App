//
//  TVDetailRepository.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - TVDetailRepository

nonisolated final class TVDetailRepository: TVDetailProviding {

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

    // MARK: - TVDetailProviding

    func series(id: Int) async throws -> TVSeries {
        let dto: TVSeriesDTO = try await network.get(
            path: APIConfig.TV.detail(seriesId: id),
            queryItems: localizedQueryItems
        )
        return dto.mapped()
    }

    func aggregateCredits(seriesID: Int) async throws -> AggregateCredits {
        let dto: AggregateCreditsDTO = try await network.get(
            path: APIConfig.TV.aggregateCredits(seriesId: seriesID),
            queryItems: localizedQueryItems
        )
        return dto.mapped()
    }

    func videos(seriesID: Int) async throws -> [Video] {
        let dto: VideosDTO = try await network.get(
            path: APIConfig.TV.videos(seriesId: seriesID),
            queryItems: localizedQueryItems
        )
        return dto.mapped()
    }

    func images(seriesID: Int) async throws -> MediaImages {
        let dto: MediaImagesDTO = try await network.get(
            path: APIConfig.TV.images(seriesId: seriesID),
            queryItems: imageQueryItems
        )
        return dto.mapped()
    }

    func recommendations(seriesID: Int, page: Int) async throws -> Page<MediaSummary> {
        let dto: MediaSummaryPageDTO = try await network.get(
            path: APIConfig.TV.recommendations(seriesId: seriesID),
            queryItems: pagedQueryItems(page: page)
        )
        return dto.mapped()
    }

    func similar(seriesID: Int, page: Int) async throws -> Page<MediaSummary> {
        let dto: MediaSummaryPageDTO = try await network.get(
            path: APIConfig.TV.similar(seriesId: seriesID),
            queryItems: pagedQueryItems(page: page)
        )
        return dto.mapped()
    }

    func watchProviders(seriesID: Int) async throws -> WatchProviders {
        let dto: WatchProvidersDTO = try await network.get(
            path: APIConfig.TV.watchProviders(seriesId: seriesID),
            queryItems: []
        )
        return dto.mapped()
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
