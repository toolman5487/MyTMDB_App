//
//  CompanyDetailRepository.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/24.
//

import Foundation

// MARK: - CompanyDetailRepository

nonisolated final class CompanyDetailRepository: CompanyDetailProviding {

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

    // MARK: - CompanyDetailProviding

    func company(id: Int) async throws -> Company {
        let dto: CompanyDetailDTO = try await network.get(
            path: APIConfig.Company.detail(id: id),
            queryItems: []
        )
        return dto.mapped()
    }

    func alternativeNames(companyID: Int) async throws -> [CompanyAlternativeName] {
        let dto: CompanyAlternativeNamesResponseDTO = try await network.get(
            path: APIConfig.Company.alternativeNames(id: companyID),
            queryItems: []
        )
        return dto.mapped()
    }

    func images(companyID: Int) async throws -> CompanyImages {
        let dto: CompanyImagesDTO = try await network.get(
            path: APIConfig.Company.images(id: companyID),
            queryItems: []
        )
        return dto.mapped()
    }

    func movies(companyID: Int, page: Int) async throws -> Page<MediaSummary> {
        let dto: TMDBPageResponse<MediaSummaryDTO> = try await network.get(
            path: APIConfig.discover(kind: .movie),
            queryItems: discoverQueryItems(kind: .movie, companyID: companyID, page: page)
        )
        return dto.mapped()
    }

    func tvShows(companyID: Int, page: Int) async throws -> Page<MediaSummary> {
        let dto: TMDBPageResponse<MediaSummaryDTO> = try await network.get(
            path: APIConfig.discover(kind: .tv),
            queryItems: discoverQueryItems(kind: .tv, companyID: companyID, page: page)
        )
        return dto.mapped()
    }

    // MARK: - Private Methods

    private func discoverQueryItems(
        kind: MediaKind,
        companyID: Int,
        page: Int
    ) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "language", value: localization.languageParameter)
        ]

        if kind == .movie {
            queryItems.append(URLQueryItem(name: "region", value: localization.regionCode))
        }

        queryItems.append(contentsOf: [
            URLQueryItem(name: "sort_by", value: "popularity.desc"),
            URLQueryItem(name: "include_adult", value: "true"),
            URLQueryItem(name: "with_companies", value: String(companyID)),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ])

        return queryItems
    }
}
