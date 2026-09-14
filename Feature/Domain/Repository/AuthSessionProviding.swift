//
//  AuthSessionProviding.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - AuthSessionProviding

nonisolated protocol AuthSessionProviding: Sendable {
    func currentSession() -> AuthSession

    func clearSession()
}
