//
//  MainMyAccountService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Foundation

// MARK: - Protocol

protocol MainMyAccountServicing {
    func fetchProfile(sessionId: String) async throws -> MainMyAccountProfileResponse
}

// MARK: - MainMyAccountService

final class MainMyAccountService: MainMyAccountServicing {

    // MARK: - Properties

    private let network: NetworkServicing

    // MARK: - Initialization

    init(network: NetworkServicing = NetworkService()) {
        self.network = network
    }

    // MARK: - Public Methods

    func fetchProfile(sessionId: String) async throws -> MainMyAccountProfileResponse {
        try await network.get(
            path: APIConfig.Account.me,
            queryItems: [URLQueryItem(name: "session_id", value: sessionId)]
        )
    }
}
