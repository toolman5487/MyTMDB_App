//
//  HomeSectionListService.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import Foundation

// MARK: - HomeSectionListServicing

nonisolated protocol HomeSectionListServicing: Sendable {
    func fetchGenres(for mediaType: MainHomeMediaType) async throws -> [HomeSectionListGenre]
}

// MARK: - HomeSectionListService

nonisolated final class HomeSectionListService: HomeSectionListServicing {

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

    func fetchGenres(for mediaType: MainHomeMediaType) async throws -> [HomeSectionListGenre] {
        switch mediaType {
        case .movie:
            let response: MainMovieGenreResponse = try await network.get(
                path: APIConfig.Genre.movieList,
                queryItems: [
                    URLQueryItem(name: "language", value: localization.languageParameter)
                ]
            )
            return response.genres.map(HomeSectionListGenre.init(movieGenre:))

        case .tv:
            let response: MainTVGenreResponse = try await network.get(
                path: APIConfig.Genre.tvList,
                queryItems: [
                    URLQueryItem(name: "language", value: localization.languageParameter)
                ]
            )
            return response.genres.map(HomeSectionListGenre.init(tvGenre:))
        }
    }
}
