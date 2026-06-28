//
//  AccountService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/5.
//

import Foundation

// MARK: - Protocol

protocol AccountServiceProtocol {
    func fetchAccount(sessionId: String) async throws -> Account
}

// MARK: - AccountService

final class AccountService: AccountServiceProtocol {

    // MARK: - Properties

    private let network: NetworkServicing

    // MARK: - Initialization

    init(network: NetworkServicing = NetworkService()) {
        self.network = network
    }

    // MARK: - Public Methods

    func fetchAccount(sessionId: String) async throws -> Account {
        try await network.get(
            path: APIConfig.Account.me,
            queryItems: [URLQueryItem(name: "session_id", value: sessionId)]
        )
    }
}
