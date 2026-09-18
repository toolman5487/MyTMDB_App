//
//  AuthenticationProviding.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - AuthenticationProviding

nonisolated protocol AuthenticationProviding: Sendable {
    func createUserSession(username: String, password: String) async throws -> String

    func createGuestSession() async throws -> String

    func deleteUserSession(sessionID: String) async throws
}
