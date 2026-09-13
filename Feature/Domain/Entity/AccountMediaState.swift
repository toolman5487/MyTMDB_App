//
//  AccountMediaState.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - AccountMediaState

/// 目前登入帳號對單一媒體的收藏與評分狀態。
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

/// TMDB 帳號寫入 API 的結果；失敗時 `message` 為伺服器回傳的原因。
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
