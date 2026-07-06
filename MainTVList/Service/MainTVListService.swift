//
//  MainTVListService.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - MainTVListServicing

nonisolated protocol MainTVListServicing: Sendable {
    func fetchGenres() async throws -> [MainTVGenre]

    func fetchSeries(
        genreID: Int,
        page: Int
    ) async throws -> MainTVListSeriesPage
}

// MARK: - MainTVListService

nonisolated final class MainTVListService: MainTVListServicing {

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

    func fetchGenres() async throws -> [MainTVGenre] {
        let response: MainTVGenreResponse = try await network.get(
            path: APIConfig.Genre.tvList,
            queryItems: [
                URLQueryItem(name: "language", value: localization.languageParameter)
            ]
        )

        return response.genres
    }

    func fetchSeries(
        genreID: Int,
        page: Int = 1
    ) async throws -> MainTVListSeriesPage {
        let response: TMDBPageResponse<TVGridSeries> = try await network.get(
            path: APIConfig.Discover.tv,
            queryItems: seriesQueryItems(genreID: genreID, page: page)
        )

        return MainTVListSeriesPage(
            genreID: genreID,
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            series: response.results
        )
    }

    // MARK: - Private Methods

    private func seriesQueryItems(genreID: Int, page: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: localization.languageParameter),
            URLQueryItem(name: "sort_by", value: "popularity.desc"),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "include_null_first_air_dates", value: "false"),
            URLQueryItem(name: "with_genres", value: String(genreID)),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ]
    }
}
