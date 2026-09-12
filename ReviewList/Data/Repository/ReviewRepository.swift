//
//  ReviewRepository.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - ReviewRepository

nonisolated final class ReviewRepository: ReviewProviding {

    // MARK: - Properties

    private let network: NetworkServicing

    // MARK: - Initialization

    init(network: NetworkServicing = NetworkService()) {
        self.network = network
    }

    // MARK: - ReviewProviding

    func reviews(
        kind: MediaKind,
        mediaID: Int,
        page: Int
    ) async throws -> Page<Review> {
        let dto: ReviewsPageDTO = try await network.get(
            path: APIConfig.reviews(kind: kind, id: mediaID),
            queryItems: [
                URLQueryItem(name: "page", value: String(max(page, 1)))
            ]
        )

        return dto.mapped()
    }
}
