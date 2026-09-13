//
//  MediaListRepository.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - MediaListRepository

nonisolated final class MediaListRepository: MediaListProviding {

    // MARK: - Properties

    private let network: NetworkServicing
    private let localization: AppLocalization
    private let genreRepository: MediaGenreProviding

    // MARK: - Initialization

    init(
        network: NetworkServicing = NetworkService(),
        localization: AppLocalization = .current,
        genreRepository: MediaGenreProviding? = nil
    ) {
        self.network = network
        self.localization = localization
        self.genreRepository = genreRepository
            ?? MediaGenreRepository(network: network, localization: localization)
    }

    // MARK: - MediaGenreProviding

    func genres(kind: MediaKind) async throws -> [MediaGenre] {
        try await genreRepository.genres(kind: kind)
    }

    func discover(
        kind: MediaKind,
        genreID: Int,
        sortOrder: MediaSortOrder,
        page: Int
    ) async throws -> Page<MediaSummary> {
        let dto: TMDBPageResponse<MediaSummaryDTO> = try await network.get(
            path: APIConfig.discover(kind: kind),
            queryItems: discoverQueryItems(
                kind: kind,
                genreID: genreID,
                sortOrder: sortOrder,
                page: page
            )
        )

        return dto.mapped()
    }

    // MARK: - Private Methods

    private func discoverQueryItems(
        kind: MediaKind,
        genreID: Int,
        sortOrder: MediaSortOrder,
        page: Int
    ) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "language", value: localization.languageParameter)
        ]

        if kind == .movie {
            queryItems.append(URLQueryItem(name: "region", value: localization.regionCode))
        }

        queryItems.append(contentsOf: [
            URLQueryItem(name: "sort_by", value: sortOrder.discoverSortValue(kind: kind)),
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

// MARK: - MediaSortOrder Discover Parameter

private extension MediaSortOrder {

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
