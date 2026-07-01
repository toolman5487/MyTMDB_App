//
//  MovieDetailReviewService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation

// MARK: - Protocol

nonisolated protocol MovieDetailReviewServicing {
    func fetchMovieReviews(movieID: Int, page: Int) async throws -> MovieDetailReviewsPage
}

extension MovieDetailReviewServicing {

    func fetchMovieReviews(movieID: Int) async throws -> MovieDetailReviewsPage {
        try await fetchMovieReviews(movieID: movieID, page: 1)
    }
}

// MARK: - MovieDetailReviewService

nonisolated final class MovieDetailReviewService: MovieDetailReviewServicing {

    // MARK: - Properties

    private let network: NetworkServicing

    // MARK: - Initialization

    init(network: NetworkServicing = NetworkService()) {
        self.network = network
    }

    // MARK: - Public Methods

    func fetchMovieReviews(movieID: Int, page: Int = 1) async throws -> MovieDetailReviewsPage {
        try await network.get(
            path: APIConfig.Movie.reviews(id: movieID),
            queryItems: [
                URLQueryItem(name: "page", value: String(max(page, 1)))
            ]
        )
    }
}
