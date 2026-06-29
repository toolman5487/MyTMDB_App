//
//  AccountViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/5.
//

import Foundation
import Observation

// MARK: - State

enum AccountState {
    case idle
    case loading
    case loaded(Account)
    case failed(message: String)
}

// MARK: - AccountViewModel

@MainActor
@Observable
final class AccountViewModel {

    // MARK: - Properties

    private(set) var state: AccountState = .idle

    private let service: AccountServiceProtocol

    // MARK: - Initialization

    init(service: AccountServiceProtocol = AccountService()) {
        self.service = service
    }

    // MARK: - Public Methods

    func loadAccount(sessionId: String) async {
        AppLogger.authentication.debug("Start loading account profile")
        state = .loading

        do {
            let account = try await service.fetchAccount(sessionId: sessionId)
            state = .loaded(account)
            AppLogger.authentication.info(
                "Account loaded successfully for user \(account.username, privacy: .public)"
            )
        } catch {
            let message = error.localizedDescription
            state = .failed(message: message)
            AppLogger.authentication.error(
                "Failed to load account: \(message, privacy: .public)"
            )
        }
    }
}
