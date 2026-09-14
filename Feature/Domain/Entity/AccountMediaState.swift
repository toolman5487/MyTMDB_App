//
//  AccountMediaState.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - AccountMediaState

nonisolated struct AccountMediaState: Sendable, Equatable, Identifiable {
    let id: Int
    let isFavorite: Bool
    let rating: Double?

    init(
        id: Int = 0,
        isFavorite: Bool = false,
        rating: Double? = nil
    ) {
        self.id = id
        self.isFavorite = isFavorite
        self.rating = rating
    }
}

// MARK: - AccountActionResult

nonisolated struct AccountActionResult: Sendable, Equatable {
    let isSuccess: Bool
    let message: String
}

// MARK: - AccountUserSession

nonisolated struct AccountUserSession: Sendable, Equatable {
    let accountID: Int
    let sessionID: String
}

// MARK: - AccountMediaError

nonisolated enum AccountMediaError: Error, Sendable, Equatable {
    case invalidIdentifier
    case invalidRatingValue
    case requiresUserLogin
}
