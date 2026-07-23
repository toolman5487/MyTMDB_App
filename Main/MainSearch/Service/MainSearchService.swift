//
//  MainSearchService.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/23.
//

import Foundation

// MARK: - MainSearchServicing

nonisolated protocol MainSearchServicing: Sendable {
    func searchAll(
        keyword: String,
        page: Int
    ) async throws -> MainSearchResultPage
}

// MARK: - MainSearchService

nonisolated final class MainSearchService: MainSearchServicing {

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

    func searchAll(
        keyword: String,
        page: Int = 1
    ) async throws -> MainSearchResultPage {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        let response: TMDBPageResponse<MainSearchResult> = try await network.get(
            path: APIConfig.Search.multi,
            queryItems: searchQueryItems(keyword: trimmedKeyword, page: page)
        )

        return MainSearchResultPage(
            keyword: trimmedKeyword,
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            results: response.results.filter { $0.mediaType != .unknown }
        )
    }

    // MARK: - Private Methods

    private func searchQueryItems(keyword: String, page: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: localization.languageParameter),
            URLQueryItem(name: "region", value: localization.regionCode),
            URLQueryItem(name: "query", value: keyword),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ]
    }
}
