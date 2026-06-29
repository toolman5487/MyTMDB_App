//
//  MainHomeService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Foundation

// MARK: - Protocol

nonisolated protocol MainHomeServicing {
    func fetchMovies(
        for category: MainHomeMovieCategory,
        page: Int
    ) async throws -> MainHomeMoviePage

    func fetchHomeSections() async throws -> [MainHomeMovieSection]
}

// MARK: - MainHomeService

nonisolated final class MainHomeService: MainHomeServicing {

    // MARK: - Properties

    private let network: NetworkServicing
    private let language: String
    private let region: String

    // MARK: - Initialization

    init(
        network: NetworkServicing = NetworkService(),
        language: String = "zh-TW",
        region: String = "TW"
    ) {
        self.network = network
        self.language = language
        self.region = region
    }

    // MARK: - Public Methods

    func fetchMovies(
        for category: MainHomeMovieCategory,
        page: Int = 1
    ) async throws -> MainHomeMoviePage {
        let response: TMDBPageResponse<MainHomeMovie> = try await network.get(
            path: category.path,
            queryItems: queryItems(for: category, page: page)
        )

        return MainHomeMoviePage(
            category: category,
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            movies: response.results
        )
    }

    func fetchHomeSections() async throws -> [MainHomeMovieSection] {
        var sections: [MainHomeMovieSection] = []

        for category in MainHomeMovieCategory.allCases {
            let page = try await fetchMovies(for: category, page: 1)
            sections.append(
                MainHomeMovieSection(
                    category: category,
                    totalResults: page.totalResults,
                    movies: page.movies
                )
            )
        }

        return sections
    }

    // MARK: - Private Methods

    private func queryItems(
        for category: MainHomeMovieCategory,
        page: Int
    ) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ]

        if category.usesRegion {
            items.append(URLQueryItem(name: "region", value: region))
        }

        return items
    }
}

// MARK: - MainHomeMovieCategory Helpers

private extension MainHomeMovieCategory {

    var path: String {
        switch self {
        case .trendingToday:
            return APIConfig.Trending.movie(timeWindow: "day")

        case .popular:
            return APIConfig.Movie.popular

        case .nowPlaying:
            return APIConfig.Movie.nowPlaying

        case .upcoming:
            return APIConfig.Movie.upcoming

        case .topRated:
            return APIConfig.Movie.topRated
        }
    }

    var usesRegion: Bool {
        switch self {
        case .trendingToday:
            return false

        case .popular, .nowPlaying, .upcoming, .topRated:
            return true
        }
    }
}
