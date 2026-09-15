//
//  UserProfileStore.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import Foundation

// MARK: - StoredUserProfile

nonisolated struct StoredUserProfile: Codable, Sendable, Equatable {
    let accountID: Int?
    let displayName: String
    let username: String
    let languageCode: String?
    let regionCode: String?
    let includesAdultContent: Bool?
    let avatarURL: URL?
    let avatarImageData: Data?

    private enum CodingKeys: String, CodingKey {
        case accountID = "accountId"
        case displayName
        case username
        case languageCode
        case regionCode
        case includesAdultContent
        case avatarURL
        case avatarImageData
    }

    init(
        accountID: Int?,
        displayName: String,
        username: String,
        languageCode: String? = nil,
        regionCode: String? = nil,
        includesAdultContent: Bool? = nil,
        avatarURL: URL?,
        avatarImageData: Data? = nil
    ) {
        self.accountID = accountID
        self.displayName = displayName
        self.username = username
        self.languageCode = languageCode
        self.regionCode = regionCode
        self.includesAdultContent = includesAdultContent
        self.avatarURL = avatarURL
        self.avatarImageData = avatarImageData
    }

    init(account: Account, avatarImageData: Data? = nil) {
        self.accountID = account.id
        self.displayName = account.name?.isEmpty == false ? account.name ?? account.username : account.username
        self.username = account.username
        self.languageCode = account.iso_639_1
        self.regionCode = account.iso_3166_1
        self.includesAdultContent = account.include_adult
        self.avatarURL = Self.makeAvatarURL(from: account)
        self.avatarImageData = avatarImageData
    }

    func updatingAvatarImageData(_ avatarImageData: Data?) -> StoredUserProfile {
        StoredUserProfile(
            accountID: accountID,
            displayName: displayName,
            username: username,
            languageCode: languageCode,
            regionCode: regionCode,
            includesAdultContent: includesAdultContent,
            avatarURL: avatarURL,
            avatarImageData: avatarImageData
        )
    }

    private static func makeAvatarURL(from account: Account) -> URL? {
        AccountAvatarURLFactory.make(
            tmdbAvatarPath: account.avatar.tmdb.avatar_path,
            gravatarHash: account.avatar.gravatar.hash
        )
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

final class UserProfileStore: UserProfileStoring {

    // MARK: - Properties

    private let preferences: AppPreferencesStorage
    private let storageKey = "StoredUserProfile"

    // MARK: - Initialization

    init(preferences: AppPreferencesStorage = .standard) {
        self.preferences = preferences
    }

    // MARK: - UserProfileStoring

    func load() -> StoredUserProfile? {
        preferences.performLocked { preferencesStore in
            load(from: preferencesStore)
        }
    }

    func save(_ profile: StoredUserProfile) {
        preferences.performLocked { preferencesStore in
            save(profile, to: preferencesStore)
        }
    }

    func save(account: Account) {
        preferences.performLocked { preferencesStore in
            let profile = StoredUserProfile(account: account)
            let existingProfile = load(from: preferencesStore)
            let avatarImageData = existingProfile?.avatarURL == profile.avatarURL
                ? existingProfile?.avatarImageData
                : nil
            save(StoredUserProfile(account: account, avatarImageData: avatarImageData), to: preferencesStore)
        }
    }

    func saveAvatarImageData(_ data: Data?) {
        preferences.performLocked { preferencesStore in
            guard let profile = load(from: preferencesStore) else { return }
            save(profile.updatingAvatarImageData(data), to: preferencesStore)
        }
    }

    func clear() {
        preferences.performLocked { preferencesStore in
            preferencesStore.removeObject(forKey: storageKey)
        }
    }

    // MARK: - Private Methods

    private func load(from preferencesStore: UserDefaults) -> StoredUserProfile? {
        guard let data = preferencesStore.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(StoredUserProfile.self, from: data)
    }

    private func save(_ profile: StoredUserProfile, to preferencesStore: UserDefaults) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        preferencesStore.set(data, forKey: storageKey)
    }
}
