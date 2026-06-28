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

    // MARK: - Public Methods

    func fetchAccount(sessionId: String) async throws -> Account {
        let url = URL(string: "\(TMDB.baseURL)/account?api_key=\(TMDB.apiKey)&session_id=\(sessionId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Account.self, from: data)
    }
}
