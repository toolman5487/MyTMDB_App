//
//  AccountProfile.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - AccountProfile

nonisolated struct AccountProfile: Sendable, Equatable, Identifiable {
    let id: Int
    let displayName: String
    let username: String
    let avatarURL: URL?
    let languageCode: String
    let regionCode: String
    let includesAdultContent: Bool
    let avatarImageData: Data?

    init(
        id: Int,
        displayName: String,
        username: String,
        avatarURL: URL?,
        languageCode: String,
        regionCode: String,
        includesAdultContent: Bool,
        avatarImageData: Data? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.avatarURL = avatarURL
        self.languageCode = languageCode
        self.regionCode = regionCode
        self.includesAdultContent = includesAdultContent
        self.avatarImageData = avatarImageData
    }
}
