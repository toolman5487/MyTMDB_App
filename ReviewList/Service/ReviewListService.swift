//
//  ReviewListService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation

// MARK: - Protocol

nonisolated protocol ReviewListServicing: Sendable {
    func fetchReviews(kind: MediaKind, mediaID: Int, page: Int) async throws -> ReviewsPage
}

extension ReviewListServicing {

    func fetchReviews(kind: MediaKind, mediaID: Int) async throws -> ReviewsPage {
        try await fetchReviews(kind: kind, mediaID: mediaID, page: 1)
    }
}

// MARK: - ReviewListService

nonisolated final class ReviewListService: ReviewListServicing {

    // MARK: - Properties

    private let network: NetworkServicing

    // MARK: - Initialization

    init(network: NetworkServicing = NetworkService()) {
        self.network = network
    }

    // MARK: - Public Methods

    func fetchReviews(
        kind: MediaKind,
        mediaID: Int,
        page: Int = 1
    ) async throws -> ReviewsPage {
        try await network.get(
            path: APIConfig.reviews(kind: kind, id: mediaID),
            queryItems: [
                URLQueryItem(name: "page", value: String(max(page, 1)))
            ]
        )
    }
}
