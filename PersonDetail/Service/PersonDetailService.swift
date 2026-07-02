//
//  PersonDetailService.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/2.
//

import Foundation

// MARK: - Protocol

nonisolated protocol PersonDetailServicing: Sendable {
    func fetchPersonDetailContent(id: Int) async throws -> PersonDetailContent

    func fetchPersonDetail(id: Int) async throws -> PersonDetail

    func fetchPersonCombinedCredits(id: Int) async throws -> PersonCombinedCreditsResponse

    func fetchPersonImages(id: Int) async throws -> PersonImagesResponse

    func fetchPersonExternalIDs(id: Int) async throws -> PersonExternalIDs
}

// MARK: - PersonDetailService

nonisolated final class PersonDetailService: PersonDetailServicing {

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

    func fetchPersonDetailContent(id: Int) async throws -> PersonDetailContent {
        async let detail = fetchPersonDetail(id: id)
        async let combinedCredits = fetchAuxiliaryContent(
            name: "person combined credits",
            id: id,
            fallback: PersonCombinedCreditsResponse(id: id)
        ) {
            try await fetchPersonCombinedCredits(id: id)
        }
        async let images = fetchAuxiliaryContent(
            name: "person images",
            id: id,
            fallback: PersonImagesResponse(id: id)
        ) {
            try await fetchPersonImages(id: id)
        }
        async let externalIDs = fetchAuxiliaryContent(
            name: "person external IDs",
            id: id,
            fallback: PersonExternalIDs(id: id)
        ) {
            try await fetchPersonExternalIDs(id: id)
        }

        return try await PersonDetailContent(
            detail: detail,
            combinedCredits: combinedCredits,
            images: images,
            externalIDs: externalIDs
        )
    }

    func fetchPersonDetail(id: Int) async throws -> PersonDetail {
        try await network.get(
            path: APIConfig.Person.detail(id: id),
            queryItems: localizedQueryItems
        )
    }

    func fetchPersonCombinedCredits(id: Int) async throws -> PersonCombinedCreditsResponse {
        try await network.get(
            path: APIConfig.Person.combinedCredits(id: id),
            queryItems: localizedQueryItems
        )
    }

    func fetchPersonImages(id: Int) async throws -> PersonImagesResponse {
        try await network.get(
            path: APIConfig.Person.images(id: id),
            queryItems: []
        )
    }

    func fetchPersonExternalIDs(id: Int) async throws -> PersonExternalIDs {
        try await network.get(
            path: APIConfig.Person.externalIds(id: id),
            queryItems: []
        )
    }

    // MARK: - Private Methods

    private var localizedQueryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: localization.languageParameter)
        ]
    }

    private func fetchAuxiliaryContent<T: Sendable>(
        name: String,
        id: Int,
        fallback: T,
        operation: @Sendable () async throws -> T
    ) async -> T {
        do {
            return try await operation()
        } catch {
            AppLogger.network.warning(
                "Failed to load \(name, privacy: .public) for person \(id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return fallback
        }
    }
}
