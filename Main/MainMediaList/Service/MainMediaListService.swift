//
//  MainMediaListService.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import Foundation

// MARK: - MainMediaListServicing

nonisolated protocol MainMediaListServicing: Sendable {
    func fetchGenres(kind: MediaKind) async throws -> [MainMediaGenre]

    func fetchItems(
        kind: MediaKind,
        genreID: Int,
        sortOption: MediaSortOption,
        page: Int
    ) async throws -> MainMediaListPage
}

// MARK: - MainMediaListService

nonisolated final class MainMediaListService: MainMediaListServicing {

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

    func fetchGenres(kind: MediaKind) async throws -> [MainMediaGenre] {
        let response: MainMediaGenreResponse = try await network.get(
            path: APIConfig.genreList(kind: kind),
            queryItems: [
                URLQueryItem(name: "language", value: localization.languageParameter)
            ]
        )

        return response.genres
    }

    func fetchItems(
        kind: MediaKind,
        genreID: Int,
        sortOption: MediaSortOption,
        page: Int = 1
    ) async throws -> MainMediaListPage {
        let response: TMDBPageResponse<MediaGridEntry> = try await network.get(
            path: APIConfig.discover(kind: kind),
            queryItems: discoverQueryItems(
                kind: kind,
                genreID: genreID,
                sortOption: sortOption,
                page: page
            )
        )

        return MainMediaListPage(
            genreID: genreID,
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            items: response.results
        )
    }

    // MARK: - Private Methods

    private func discoverQueryItems(
        kind: MediaKind,
        genreID: Int,
        sortOption: MediaSortOption,
        page: Int
    ) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "language", value: localization.languageParameter)
        ]

        if kind == .movie {
            queryItems.append(URLQueryItem(name: "region", value: localization.regionCode))
        }

        queryItems.append(contentsOf: [
            URLQueryItem(name: "sort_by", value: sortOption.discoverSortValue(kind: kind)),
            URLQueryItem(name: "include_adult", value: "false")
        ])

        switch kind {
        case .movie:
            queryItems.append(URLQueryItem(name: "include_video", value: "false"))

        case .tv:
            queryItems.append(URLQueryItem(name: "include_null_first_air_dates", value: "false"))
        }

        queryItems.append(contentsOf: [
            URLQueryItem(name: "with_genres", value: String(genreID)),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ])

        return queryItems
    }
}

// MARK: - MediaSortOption

private extension MediaSortOption {

    func discoverSortValue(kind: MediaKind) -> String {
        let dateField = kind == .movie ? "release_date" : "first_air_date"
        let titleField = kind == .movie ? "title" : "name"

        switch self {
        case .popularity:
            return "popularity.desc"

        case .ratingHighToLow:
            return "vote_average.desc"

        case .ratingLowToHigh:
            return "vote_average.asc"

        case .newestDate:
            return "\(dateField).desc"

        case .oldestDate:
            return "\(dateField).asc"

        case .titleAscending:
            return "\(titleField).asc"

        case .titleDescending:
            return "\(titleField).desc"
        }
    }
}
