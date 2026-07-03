//
//  MainMovieListService.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import Foundation

// MARK: - MainMovieListServicing

nonisolated protocol MainMovieListServicing: Sendable {
    func fetchGenres() async throws -> [MainMovieGenre]

    func fetchMovies(
        genreID: Int,
        page: Int
    ) async throws -> MainMovieListMoviePage

    func searchMovies(
        keyword: String,
        page: Int
    ) async throws -> MainMovieSearchResultPage
}

// MARK: - MainMovieListService

nonisolated final class MainMovieListService: MainMovieListServicing {

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

    func fetchGenres() async throws -> [MainMovieGenre] {
        let response: MainMovieGenreResponse = try await network.get(
            path: APIConfig.Genre.movieList,
            queryItems: [
                URLQueryItem(name: "language", value: localization.languageParameter)
            ]
        )

        return response.genres
    }

    func fetchMovies(
        genreID: Int,
        page: Int = 1
    ) async throws -> MainMovieListMoviePage {
        let response: TMDBPageResponse<MainMovieListMovie> = try await network.get(
            path: APIConfig.Discover.movie,
            queryItems: movieQueryItems(genreID: genreID, page: page)
        )

        return MainMovieListMoviePage(
            genreID: genreID,
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            movies: response.results
        )
    }

    func searchMovies(
        keyword: String,
        page: Int = 1
    ) async throws -> MainMovieSearchResultPage {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        let response: TMDBPageResponse<MainMovieListMovie> = try await network.get(
            path: APIConfig.Search.movie,
            queryItems: searchQueryItems(keyword: trimmedKeyword, page: page)
        )

        return MainMovieSearchResultPage(
            keyword: trimmedKeyword,
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            movies: response.results
        )
    }

    // MARK: - Private Methods

    private func movieQueryItems(genreID: Int, page: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: localization.languageParameter),
            URLQueryItem(name: "region", value: localization.regionCode),
            URLQueryItem(name: "sort_by", value: "popularity.desc"),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "include_video", value: "false"),
            URLQueryItem(name: "with_genres", value: String(genreID)),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ]
    }

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
