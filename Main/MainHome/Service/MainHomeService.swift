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
        try Task.checkCancellation()

        let results = try await withThrowingTaskGroup(
            of: MainHomeSectionLoadResult.self,
            returning: [MainHomeSectionLoadResult].self
        ) { group in
            for category in MainHomeContentCategory.allCases {
                group.addTask(priority: .userInitiated) { [self] in
                    do {
                        let page = try await fetchContent(for: category, page: 1)
                        return MainHomeSectionLoadResult.loaded(
                            MainHomeContentSection(
                                category: category,
                                totalResults: page.totalResults,
                                contents: Array(page.contents.prefix(Configuration.homeSectionItemLimit))
                            )
                        )
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch {
                        try Task.checkCancellation()
                        return MainHomeSectionLoadResult.failed(
                            category: category,
                            message: error.errorMessage
                        )
                    }
                }
            }

            var completedResults: [MainHomeSectionLoadResult] = []
            completedResults.reserveCapacity(MainHomeContentCategory.allCases.count)

            for try await result in group {
                completedResults.append(result)
            }

            return completedResults
        }

        try Task.checkCancellation()

        let sections = results.compactMap(\.section)
        let failures = results.compactMap(\.failure)

        for failure in failures {
            AppLogger.network.warning(
                "Failed to load home section \(String(describing: failure.category), privacy: .public): \(failure.message.message, privacy: .public)"
            )
        }

        guard !sections.isEmpty else {
            throw MainHomeSectionsLoadingError(
                errorMessage: failures.first?.message ?? .emptyContent
            )
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

// MARK: - MainHomeSectionLoadResult

private nonisolated enum MainHomeSectionLoadResult: Sendable {
    case loaded(MainHomeContentSection)
    case failed(category: MainHomeContentCategory, message: ErrorMessage)

    var section: MainHomeContentSection? {
        guard case .loaded(let section) = self else { return nil }
        return section
    }

    var failure: (category: MainHomeContentCategory, message: ErrorMessage)? {
        guard case .failed(let category, let message) = self else { return nil }
        return (category, message)
    }
}

// MARK: - MainHomeSectionsLoadingError

private nonisolated struct MainHomeSectionsLoadingError: Error, ErrorMessageConvertible, Sendable {
    let errorMessage: ErrorMessage
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
