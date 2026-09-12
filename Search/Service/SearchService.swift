//
//  SearchService.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - SearchServicing

nonisolated protocol SearchServicing: Sendable {
    func search(
        kind: MediaKind,
        keyword: String,
        page: Int
    ) async throws -> SearchResultPage
}

// MARK: - SearchService

nonisolated final class SearchService: SearchServicing {

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

    func search(
        kind: MediaKind,
        keyword: String,
        page: Int = 1
    ) async throws -> SearchResultPage {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        let response: TMDBPageResponse<MediaGridEntry> = try await network.get(
            path: APIConfig.search(kind: kind),
            queryItems: searchQueryItems(kind: kind, keyword: trimmedKeyword, page: page)
        )

        return SearchResultPage(
            keyword: trimmedKeyword,
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            entries: response.results
        )
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
