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
        sortOption: MediaSortOption,
        page: Int
    ) async throws -> MainMovieListMoviePage
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
        sortOption: MediaSortOption,
        page: Int = 1
    ) async throws -> MainMovieListMoviePage {
        let response: TMDBPageResponse<MediaGridEntry> = try await network.get(
            path: APIConfig.Discover.movie,
            queryItems: movieQueryItems(
                genreID: genreID,
                sortOption: sortOption,
                page: page
            )
        )

        return MainMovieListMoviePage(
            genreID: genreID,
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            movies: response.results
        )
    }

    // MARK: - Private Methods

    private func movieQueryItems(
        genreID: Int,
        sortOption: MediaSortOption,
        page: Int
    ) -> [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: localization.languageParameter),
            URLQueryItem(name: "region", value: localization.regionCode),
            URLQueryItem(name: "sort_by", value: sortOption.discoverSortValue),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "include_video", value: "false"),
            URLQueryItem(name: "with_genres", value: String(genreID)),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ]
    }
}

// MARK: - MediaSortOption

private extension MediaSortOption {
    var discoverSortValue: String {
        switch self {
        case .popularity:
            return "popularity.desc"

        case .ratingHighToLow:
            return "vote_average.desc"

        case .ratingLowToHigh:
            return "vote_average.asc"

        case .newestDate:
            return "release_date.desc"

        case .oldestDate:
            return "release_date.asc"

        case .titleAscending:
            return "title.asc"

        case .titleDescending:
            return "title.desc"
        }
    }
}
