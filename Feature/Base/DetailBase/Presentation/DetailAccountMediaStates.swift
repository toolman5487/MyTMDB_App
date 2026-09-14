//
//  DetailAccountMediaStates.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import Foundation

// MARK: - AccountMediaFavoriteState

nonisolated enum AccountMediaFavoriteState: Sendable, Equatable {
    case unavailable
    case requiresUserLogin
    case ready(isFavorite: Bool)
    case updating(isFavorite: Bool)

    var isFavorite: Bool {
        switch self {
        case .unavailable, .requiresUserLogin:
            return false

        case .ready(let isFavorite), .updating(let isFavorite):
            return isFavorite
        }
    }

    var isButtonEnabled: Bool {
        switch self {
        case .unavailable, .updating:
            return false

        case .requiresUserLogin, .ready:
            return true
        }
    }

    var requiresUserLogin: Bool {
        if case .requiresUserLogin = self {
            return true
        }
        return false
    }
}

// MARK: - AccountMediaRatingState

nonisolated enum AccountMediaRatingState: Sendable, Equatable {
    case unavailable
    case requiresUserLogin
    case ready(value: Double?)
    case updating(value: Double?)

    var value: Double? {
        switch self {
        case .unavailable, .requiresUserLogin:
            return nil

        case .ready(let value), .updating(let value):
            return value
        }
    }

    var isButtonEnabled: Bool {
        switch self {
        case .unavailable, .updating:
            return false

        case .requiresUserLogin, .ready:
            return true
        }
    }

    var requiresUserLogin: Bool {
        if case .requiresUserLogin = self {
            return true
        }
        return false
    }
}
