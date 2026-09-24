//
//  MainSearchRepository.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - MainSearchRepository

nonisolated final class MainSearchRepository: MainSearchProviding {

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

    // MARK: - MainSearchProviding

    func dailyTrending(page: Int) async throws -> Page<MainSearchResult> {
        let dto: TMDBPageResponse<MainSearchResultDTO> = try await network.get(
            path: APIConfig.Trending.all(timeWindow: "day"),
            queryItems: pagedQueryItems(page: page)
        )

        return dto.mapped()
    }

    func popularPeople(page: Int) async throws -> Page<MainSearchPopularPerson> {
        let dto: TMDBPageResponse<MainSearchPopularPersonDTO> = try await network.get(
            path: APIConfig.Person.popular,
            queryItems: pagedQueryItems(page: page)
        )

        return dto.mapped()
    }

    func searchResults(keyword: String, page: Int) async throws -> Page<MainSearchResult> {
        let dto: TMDBPageResponse<MainSearchResultDTO> = try await network.get(
            path: APIConfig.Search.multi,
            queryItems: searchQueryItems(keyword: keyword, page: page)
        )

        return dto.mapped()
    }

    func searchCompanies(keyword: String, page: Int) async throws -> Page<MainSearchCompanyResult> {
        let dto: TMDBPageResponse<MainSearchCompanyResultDTO> = try await network.get(
            path: APIConfig.Search.company,
            queryItems: companySearchQueryItems(keyword: keyword, page: page)
        )

        return dto.mapped()
    }

    // MARK: - Helpers

    private func pagedQueryItems(page: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: localization.languageParameter),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ]
    }

    private func searchQueryItems(keyword: String, page: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: localization.languageParameter),
            URLQueryItem(name: "region", value: localization.regionCode),
            URLQueryItem(name: "query", value: keyword.trimmingCharacters(in: .whitespacesAndNewlines)),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ]
    }

    private func companySearchQueryItems(keyword: String, page: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "query", value: keyword.trimmingCharacters(in: .whitespacesAndNewlines)),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ]
    }
}
