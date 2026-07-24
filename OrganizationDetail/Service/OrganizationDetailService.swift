//
//  OrganizationDetailService.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/24.
//

import Foundation

// MARK: - Protocol

nonisolated protocol OrganizationDetailServicing: Sendable {
    func fetchContent(kind: OrganizationKind, id: Int) async throws -> OrganizationDetailContent
}

// MARK: - OrganizationDetailService

nonisolated final class OrganizationDetailService: OrganizationDetailServicing {

    private let network: NetworkServicing

    init(network: NetworkServicing = NetworkService()) {
        self.network = network
    }

    func fetchContent(kind: OrganizationKind, id: Int) async throws -> OrganizationDetailContent {
        async let detail: OrganizationDetail = network.get(
            path: kind.detailPath(id: id),
            queryItems: []
        )
        async let alternativeNames = fetchAlternativeNames(kind: kind, id: id)
        async let images = fetchImages(kind: kind, id: id)

        return try await OrganizationDetailContent(
            kind: kind,
            detail: detail,
            alternativeNames: alternativeNames,
            images: images
        )
    }

    private func fetchAlternativeNames(
        kind: OrganizationKind,
        id: Int
    ) async -> OrganizationAlternativeNamesResponse {
        do {
            return try await network.get(
                path: kind.alternativeNamesPath(id: id),
                queryItems: []
            )
        } catch {
            AppLogger.network.warning(
                "Failed to load alternative names for \(kind.displayName, privacy: .public) \(id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return OrganizationAlternativeNamesResponse(id: id)
        }
    }

    private func fetchImages(
        kind: OrganizationKind,
        id: Int
    ) async -> OrganizationImagesResponse {
        do {
            return try await network.get(
                path: kind.imagesPath(id: id),
                queryItems: []
            )
        } catch {
            AppLogger.network.warning(
                "Failed to load logos for \(kind.displayName, privacy: .public) \(id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return OrganizationImagesResponse(id: id)
        }
    }
}
