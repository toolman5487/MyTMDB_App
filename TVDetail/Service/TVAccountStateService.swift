//
//  TVAccountStateService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/2.
//

import Foundation

// MARK: - TVAccountStateServicing

nonisolated protocol TVAccountStateServicing: Sendable {
    func fetchTVAccountStates(seriesID: Int, sessionId: String) async throws -> AccountMediaStatesResponse
}

// MARK: - TVAccountStateService

nonisolated final class TVAccountStateService: TVAccountStateServicing {

    // MARK: - Properties

    private let network: NetworkServicing

    // MARK: - Initialization

    init(network: NetworkServicing = NetworkService()) {
        self.network = network
    }

    // MARK: - TVAccountStateServicing

    func fetchTVAccountStates(seriesID: Int, sessionId: String) async throws -> AccountMediaStatesResponse {
        try await network.get(
            path: APIConfig.TV.accountStates(seriesId: seriesID),
            queryItems: [
                URLQueryItem(name: "session_id", value: sessionId)
            ]
        )
    }
}
