//
//  AccountContentProviding.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - AccountContentProviding

nonisolated protocol AccountContentProviding: AccountProfileProviding {
    func cachedProfile() -> AccountProfile?

    func collection(
        destination: MemberCenterDestination,
        accountID: Int,
        sessionID: String,
        page: Int,
        posterFallbackLimit: Int
    ) async throws -> AccountCollection
}
