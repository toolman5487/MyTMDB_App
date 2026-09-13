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

    // MARK: - Initialization

    init(
        network: NetworkServicing = NetworkService(),
        localization: AppLocalization = .current
    ) {
        self.network = network
        self.localization = localization
    }

    // MARK: - MediaListProviding

    func genres(kind: MediaKind) async throws -> [MediaGenre] {
        let dto: MediaGenreListDTO = try await network.get(
            path: APIConfig.genreList(kind: kind),
            queryItems: [
                URLQueryItem(name: "language", value: localization.languageParameter)
            ]
        )

        return dto.mapped()
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

        return Page(
            number: dto.page,
            totalPages: dto.totalPages,
            totalResults: dto.totalResults,
            items: dto.results.map { $0.mapped() }
        )
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
