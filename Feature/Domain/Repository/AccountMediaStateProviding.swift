//
//  AccountMediaStateProviding.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - AccountMediaStateProviding

nonisolated protocol AccountMediaStateProviding: Sendable {
    func mediaState(
        kind: MediaKind,
        mediaID: Int,
        sessionID: String
    ) async throws -> AccountMediaState

    func updateFavorite(
        accountID: Int,
        sessionID: String,
        kind: MediaKind,
        mediaID: Int,
        isFavorite: Bool
    ) async throws -> AccountActionResult

    func submitRating(
        sessionID: String,
        target: AccountMediaRatingTarget,
        value: Double
    ) async throws -> AccountActionResult

    func deleteRating(
        sessionID: String,
        target: AccountMediaRatingTarget
    ) async throws -> AccountActionResult
}

// MARK: - AccountSessionProviding

nonisolated protocol AccountSessionProviding: Sendable {
    func currentUserSession() async throws -> AccountUserSession?
}
