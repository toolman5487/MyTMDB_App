//
//  MovieAccountStateService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import Foundation

// MARK: - MovieAccountStateServicing

nonisolated protocol MovieAccountStateServicing: Sendable {
    func fetchMovieAccountStates(id: Int, sessionId: String) async throws -> AccountMediaStatesResponse
}

// MARK: - MovieAccountStateService

nonisolated final class MovieAccountStateService: MovieAccountStateServicing {

    // MARK: - Properties

    private let network: NetworkServicing

    // MARK: - Initialization

    init(network: NetworkServicing = NetworkService()) {
        self.network = network
    }

    // MARK: - MovieAccountStateServicing

    func fetchMovieAccountStates(id: Int, sessionId: String) async throws -> AccountMediaStatesResponse {
        try await network.get(
            path: APIConfig.Movie.accountStates(id: id),
            queryItems: [
                URLQueryItem(name: "session_id", value: sessionId)
            ]
        )
    }
}
