//
//  AccountSessionProviding.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - AccountSessionProviding

nonisolated protocol AccountSessionProviding: Sendable {
    func currentUserSession() async throws -> AccountUserSession?
}
