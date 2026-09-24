//
//  LoadCompanyDetailUseCase.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/24.
//

import Foundation

// MARK: - LoadCompanyDetailUseCase

nonisolated protocol LoadCompanyDetailUseCase: Sendable {
    func callAsFunction(companyID: Int) async throws -> CompanyDetailContent
}

// MARK: - DefaultLoadCompanyDetailUseCase

nonisolated struct DefaultLoadCompanyDetailUseCase: LoadCompanyDetailUseCase {

    // MARK: - Properties

    private let repository: CompanyDetailProviding
    private let failureReporter: AuxiliaryLoadFailureReporting

    // MARK: - Initialization

    init(
        repository: CompanyDetailProviding,
        failureReporter: AuxiliaryLoadFailureReporting
    ) {
        self.repository = repository
        self.failureReporter = failureReporter
    }

    // MARK: - LoadCompanyDetailUseCase

    func callAsFunction(companyID: Int) async throws -> CompanyDetailContent {
        guard companyID > 0 else { throw CompanyDetailError.invalidIdentifier }

        async let alternativeNames = optional(
            name: "company alternative names",
            companyID: companyID,
            fallback: [CompanyAlternativeName]()
        ) {
            try await repository.alternativeNames(companyID: companyID)
        }
        async let images = optional(
            name: "company images",
            companyID: companyID,
            fallback: CompanyImages.empty(id: companyID)
        ) {
            try await repository.images(companyID: companyID)
        }
        async let movies = optional(
            name: "company movies",
            companyID: companyID,
            fallback: Page<MediaSummary>.empty()
        ) {
            try await repository.movies(companyID: companyID, page: 1)
        }
        async let tvShows = optional(
            name: "company tv shows",
            companyID: companyID,
            fallback: Page<MediaSummary>.empty()
        ) {
            try await repository.tvShows(companyID: companyID, page: 1)
        }

        let detail = try await repository.company(id: companyID)

        return await CompanyDetailContent(
            detail: detail,
            alternativeNames: alternativeNames,
            images: images,
            movies: movies,
            tvShows: tvShows
        )
    }

    // MARK: - Private Helpers

    private func optional<T: Sendable>(
        name: String,
        companyID: Int,
        fallback: T,
        operation: @Sendable () async throws -> T
    ) async -> T {
        do {
            return try await operation()
        } catch {
            failureReporter.reportAuxiliaryFailure(name, target: "company \(companyID)", error: error)
            return fallback
        }
    }
}
