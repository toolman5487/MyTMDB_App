//
//  AccountAvatarProviding.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - AccountAvatarProviding

nonisolated protocol AccountAvatarProviding: Sendable {
    func avatarImageData(sessionID: String) async throws -> Data?
}
