//
//  HomeContentRepository.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - HomeContentRepository

nonisolated final class HomeContentRepository: HomeContentProviding {

    // MARK: - Properties

    private let network: NetworkServicing
    private let localization: AppLocalization

    // MARK: - Initialization

    init(
        network: NetworkServicing,
        localization: AppLocalization = .current
    ) {
        self.network = network
        self.localization = localization
    }

    // MARK: - HomeContentProviding

    func content(
        category: HomeCategory,
        page: Int
    ) async throws -> Page<MediaSummary> {
        let dto: TMDBPageResponse<MediaSummaryDTO> = try await network.get(
            path: category.path,
            queryItems: queryItems(for: category, page: page)
        )

        return dto.mapped()
    }

    // MARK: - Private Methods

    private func queryItems(
        for category: HomeCategory,
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

// MARK: - HomeCategory Endpoint

private extension HomeCategory {

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
