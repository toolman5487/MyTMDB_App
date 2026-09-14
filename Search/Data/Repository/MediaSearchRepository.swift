//
//  MediaSearchRepository.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - MediaSearchRepository

nonisolated final class MediaSearchRepository: MediaSearchProviding {

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

    // MARK: - MediaSearchProviding

    func search(kind: MediaKind, keyword: String, page: Int) async throws -> Page<MediaSummary> {
        let dto: TMDBPageResponse<MediaSummaryDTO> = try await network.get(
            path: APIConfig.search(kind: kind),
            queryItems: searchQueryItems(kind: kind, keyword: keyword, page: page)
        )

        return dto.mapped()
    }

    // MARK: - Private Methods

    private func searchQueryItems(
        kind: MediaKind,
        keyword: String,
        page: Int
    ) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "language", value: localization.languageParameter)
        ]

        if kind == .movie {
            queryItems.append(URLQueryItem(name: "region", value: localization.regionCode))
        }

        queryItems.append(contentsOf: [
            URLQueryItem(name: "query", value: keyword),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ])

        return queryItems
    }
}
