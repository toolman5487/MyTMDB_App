//
//  MainHomeService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Foundation

// MARK: - Protocol

nonisolated protocol MainHomeServicing: Sendable {
    func fetchContent(
        for category: MainHomeContentCategory,
        page: Int
    ) async throws -> MainHomeContentPage

    func fetchHomeSections() async throws -> [MainHomeContentSection]
}

// MARK: - MainHomeService

nonisolated final class MainHomeService: MainHomeServicing {

    private enum Configuration {
        static let homeSectionItemLimit = 10
    }

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

    func fetchContent(
        for category: MainHomeContentCategory,
        page: Int = 1
    ) async throws -> MainHomeContentPage {
        let response: TMDBPageResponse<MainHomeContent> = try await network.get(
            path: category.path,
            queryItems: queryItems(for: category, page: page)
        )

        return MainHomeContentPage(
            category: category,
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            contents: response.results
        )
    }

    func fetchHomeSections() async throws -> [MainHomeContentSection] {
        var sections: [MainHomeContentSection] = []
        var firstError: Error?

        for category in MainHomeContentCategory.allCases {
            do {
                let page = try await fetchContent(for: category, page: 1)
                sections.append(
                    MainHomeContentSection(
                        category: category,
                        totalResults: page.totalResults,
                        contents: Array(page.contents.prefix(Configuration.homeSectionItemLimit))
                    )
                )
            } catch {
                if firstError == nil {
                    firstError = error
                }
                AppLogger.network.warning(
                    "Failed to load home section \(String(describing: category), privacy: .public): \(error.localizedDescription, privacy: .public)"
                )
            }
        }

        if sections.isEmpty, let firstError {
            throw firstError
        }

        return sections
    }

    // MARK: - Private Methods

    private func queryItems(
        for category: MainHomeContentCategory,
        page: Int
    ) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "language", value: localization.languageParameter),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ]

        if category.usesRegion {
            items.append(URLQueryItem(name: "region", value: localization.regionCode))
        }

        if category.usesTimeZone {
            items.append(URLQueryItem(name: "timezone", value: localization.timeZoneIdentifier))
        }

        return items
    }
}

// MARK: - MainHomeContentCategory Helpers

private extension MainHomeContentCategory {

    var path: String {
        switch self {
        case .trendingMovies:
            return APIConfig.Trending.movie(timeWindow: "day")

        case .trendingTV:
            return APIConfig.Trending.tv(timeWindow: "day")

        case .popularMovies:
            return APIConfig.Movie.popular

        case .popularTV:
            return APIConfig.TV.popular

        case .nowPlayingMovies:
            return APIConfig.Movie.nowPlaying

        case .onTheAirTV:
            return APIConfig.TV.onTheAir

        case .upcomingMovies:
            return APIConfig.Movie.upcoming

        case .airingTodayTV:
            return APIConfig.TV.airingToday

        case .topRatedMovies:
            return APIConfig.Movie.topRated

        case .topRatedTV:
            return APIConfig.TV.topRated
        }
    }

    var usesRegion: Bool {
        switch self {
        case .trendingMovies, .trendingTV, .popularTV, .onTheAirTV, .airingTodayTV, .topRatedTV:
            return false

        case .popularMovies, .nowPlayingMovies, .upcomingMovies, .topRatedMovies:
            return true
        }
    }

    var usesTimeZone: Bool {
        switch self {
        case .onTheAirTV, .airingTodayTV:
            return true

        case .trendingMovies, .trendingTV, .popularMovies, .popularTV, .nowPlayingMovies,
                .upcomingMovies, .topRatedMovies, .topRatedTV:
            return false
        }
    }
}
