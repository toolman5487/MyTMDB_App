//
//  AccountProfileProviding.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - AccountProfileProviding

nonisolated protocol AccountProfileProviding: Sendable {
    func cachedProfile() -> AccountProfile?

    func profile(sessionID: String) async throws -> AccountProfile

    func clearCachedProfile()
}
