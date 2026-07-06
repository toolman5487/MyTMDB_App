//
//  TVSearchService.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - TVSearchServicing

nonisolated protocol TVSearchServicing: Sendable {
    func searchSeries(
        keyword: String,
        page: Int
    ) async throws -> TVSearchResultPage
}

// MARK: - TVSearchService

nonisolated final class TVSearchService: TVSearchServicing {

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

    func searchSeries(
        keyword: String,
        page: Int = 1
    ) async throws -> TVSearchResultPage {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        let response: TMDBPageResponse<TVGridSeries> = try await network.get(
            path: APIConfig.Search.tv,
            queryItems: searchQueryItems(keyword: trimmedKeyword, page: page)
        )

        return TVSearchResultPage(
            keyword: trimmedKeyword,
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            series: response.results
        )
    }

    // MARK: - Private Methods

    private func searchQueryItems(keyword: String, page: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: localization.languageParameter),
            URLQueryItem(name: "query", value: keyword),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ]
    }
}
