//
//  MovieSearchService.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - MovieSearchServicing

nonisolated protocol MovieSearchServicing: Sendable {
    func searchMovies(
        keyword: String,
        page: Int
    ) async throws -> MovieSearchResultPage
}

// MARK: - MovieSearchService

nonisolated final class MovieSearchService: MovieSearchServicing {

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

    func searchMovies(
        keyword: String,
        page: Int = 1
    ) async throws -> MovieSearchResultPage {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        let response: TMDBPageResponse<MovieGridMovie> = try await network.get(
            path: APIConfig.Search.movie,
            queryItems: searchQueryItems(keyword: trimmedKeyword, page: page)
        )

        return MovieSearchResultPage(
            keyword: trimmedKeyword,
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            movies: response.results
        )
    }

    // MARK: - Private Methods

    private func searchQueryItems(keyword: String, page: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: localization.languageParameter),
            URLQueryItem(name: "region", value: localization.regionCode),
            URLQueryItem(name: "query", value: keyword),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ]
    }
}
