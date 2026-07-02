//
//  TVDetailReviewService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/2.
//

import Foundation

// MARK: - Protocol

nonisolated protocol TVDetailReviewServicing {
    func fetchTVReviews(seriesID: Int, page: Int) async throws -> TVDetailReviewsPage
}

extension TVDetailReviewServicing {

    func fetchTVReviews(seriesID: Int) async throws -> TVDetailReviewsPage {
        try await fetchTVReviews(seriesID: seriesID, page: 1)
    }
}

// MARK: - TVDetailReviewService

nonisolated final class TVDetailReviewService: TVDetailReviewServicing {

    // MARK: - Properties

    private let network: NetworkServicing

    // MARK: - Initialization

    init(network: NetworkServicing = NetworkService()) {
        self.network = network
    }

    // MARK: - Public Methods

    func fetchTVReviews(seriesID: Int, page: Int = 1) async throws -> TVDetailReviewsPage {
        try await network.get(
            path: APIConfig.TV.reviews(seriesId: seriesID),
            queryItems: [
                URLQueryItem(name: "page", value: String(max(page, 1)))
            ]
        )
    }
}
