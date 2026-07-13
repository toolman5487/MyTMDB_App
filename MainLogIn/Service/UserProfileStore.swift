//
//  UserProfileStore.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import Foundation

// MARK: - StoredUserProfile

nonisolated struct StoredUserProfile: Codable, Sendable, Equatable {
    let accountId: Int?
    let displayName: String
    let username: String
    let avatarURL: URL?
    let avatarImageData: Data?

    init(
        accountId: Int?,
        displayName: String,
        username: String,
        avatarURL: URL?,
        avatarImageData: Data? = nil
    ) {
        self.accountId = accountId
        self.displayName = displayName
        self.username = username
        self.avatarURL = avatarURL
        self.avatarImageData = avatarImageData
    }

    init(account: Account, avatarImageData: Data? = nil) {
        self.accountId = account.id
        self.displayName = account.name?.isEmpty == false ? account.name ?? account.username : account.username
        self.username = account.username
        self.avatarURL = Self.makeAvatarURL(from: account)
        self.avatarImageData = avatarImageData
    }

    func updatingAvatarImageData(_ avatarImageData: Data?) -> StoredUserProfile {
        StoredUserProfile(
            accountId: accountId,
            displayName: displayName,
            username: username,
            avatarURL: avatarURL,
            avatarImageData: avatarImageData
        )
    }

    var headerContent: MainMemberCenterProfileHeaderContent {
        MainMemberCenterProfileHeaderContent(
            displayName: displayName,
            subtitle: "@\(username)",
            avatarURL: avatarURL,
            avatarImageData: avatarImageData
        )
    }

    private static func makeAvatarURL(from account: Account) -> URL? {
        if let avatarPath = account.avatar.tmdb.avatar_path,
           !avatarPath.isEmpty,
           let url = APIConfig.tmdbImageURL(path: avatarPath, size: .w185) {
            return url
        }

        let hash = account.avatar.gravatar.hash
        guard !hash.isEmpty else { return nil }
        return APIConfig.gravatarURL(hash: hash)
    }
}

// MARK: - UserProfileStoring

nonisolated protocol UserProfileStoring: Sendable {
    func load() -> StoredUserProfile?
    func save(_ profile: StoredUserProfile)
    func save(account: Account)
    func saveAvatarImageData(_ data: Data?)
    func clear()
}

// MARK: - UserProfileStore

final class UserProfileStore: UserProfileStoring, @unchecked Sendable {

    // MARK: - Properties

    private let defaults: UserDefaults
    private let storageKey = "StoredUserProfile"

    // MARK: - Initialization

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - UserProfileStoring

    func load() -> StoredUserProfile? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(StoredUserProfile.self, from: data)
    }

    func save(_ profile: StoredUserProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: storageKey)
    }

    func save(account: Account) {
        let profile = StoredUserProfile(account: account)
        let existingProfile = load()
        let avatarImageData = existingProfile?.avatarURL == profile.avatarURL
            ? existingProfile?.avatarImageData
            : nil
        save(StoredUserProfile(account: account, avatarImageData: avatarImageData))
    }

    func saveAvatarImageData(_ data: Data?) {
        guard let profile = load() else { return }
        save(profile.updatingAvatarImageData(data))
    }

    func clear() {
        defaults.removeObject(forKey: storageKey)
    }
}
