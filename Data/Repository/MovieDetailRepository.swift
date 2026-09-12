//
//  MovieDetailRepository.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - MovieDetailRepository

nonisolated final class MovieDetailRepository: MovieDetailProviding {

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

    // MARK: - MovieDetailProviding

    func movie(id: Int) async throws -> Movie {
        let dto: MovieDetailDTO = try await network.get(
            path: APIConfig.Movie.detail(id: id),
            queryItems: localizedQueryItems
        )
        return dto.mapped()
    }

    func credits(movieID: Int) async throws -> MovieCredits {
        let dto: MovieCreditsDTO = try await network.get(
            path: APIConfig.Movie.credits(id: movieID),
            queryItems: []
        )
        return dto.mapped()
    }

    func videos(movieID: Int) async throws -> [Video] {
        let dto: MovieVideosDTO = try await network.get(
            path: APIConfig.Movie.videos(id: movieID),
            queryItems: localizedQueryItems
        )
        return dto.mapped()
    }

    func images(movieID: Int) async throws -> MediaImages {
        let dto: MediaImagesDTO = try await network.get(
            path: APIConfig.Movie.images(id: movieID),
            queryItems: imageQueryItems
        )
        return dto.mapped()
    }

    func collection(id: Int) async throws -> MovieCollection {
        let dto: MovieCollectionDTO = try await network.get(
            path: APIConfig.Collection.detail(id: id),
            queryItems: localizedQueryItems
        )
        return dto.mapped()
    }

    func recommendations(movieID: Int, page: Int) async throws -> Page<MovieSummary> {
        let dto: MovieSummaryPageDTO = try await network.get(
            path: APIConfig.Movie.recommendations(id: movieID),
            queryItems: pagedQueryItems(page: page)
        )
        return dto.mapped()
    }

    func similar(movieID: Int, page: Int) async throws -> Page<MovieSummary> {
        let dto: MovieSummaryPageDTO = try await network.get(
            path: APIConfig.Movie.similar(id: movieID),
            queryItems: pagedQueryItems(page: page)
        )
        return dto.mapped()
    }

    func watchProviders(movieID: Int) async throws -> WatchProviders {
        let dto: WatchProvidersDTO = try await network.get(
            path: APIConfig.Movie.watchProviders(id: movieID),
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
