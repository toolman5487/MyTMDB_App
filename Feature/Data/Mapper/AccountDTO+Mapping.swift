//
//  AccountDTO+Mapping.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - Account Mapping

extension Account {

    func mapped(avatarImageData: Data? = nil) -> AccountProfile {
        AccountProfile(
            id: id,
            displayName: name?.isEmpty == false ? name ?? username : username,
            username: username,
            avatarURL: AccountAvatarURLFactory.make(
                tmdbAvatarPath: avatar.tmdb.avatar_path,
                gravatarHash: avatar.gravatar.hash
            ),
            languageCode: iso_639_1,
            regionCode: iso_3166_1,
            includesAdultContent: include_adult,
            avatarImageData: avatarImageData
        )
    }
}

// MARK: - StoredUserProfile Mapping

extension StoredUserProfile {

    func mapped() -> AccountProfile? {
        guard let accountId else { return nil }

        return AccountProfile(
            id: accountId,
            displayName: displayName,
            username: username,
            avatarURL: avatarURL,
            languageCode: languageCode ?? "",
            regionCode: regionCode ?? "",
            includesAdultContent: includesAdultContent ?? false,
            avatarImageData: avatarImageData
        )
    }
}

// MARK: - AccountAvatarURLFactory

nonisolated enum AccountAvatarURLFactory {

    static func make(tmdbAvatarPath: String?, gravatarHash: String) -> URL? {
        if let tmdbAvatarPath,
           !tmdbAvatarPath.isEmpty,
           let url = TMDBResourceURL.image(path: tmdbAvatarPath, size: .w185) {
            return url
        }

        guard !gravatarHash.isEmpty else { return nil }
        return TMDBResourceURL.gravatar(hash: gravatarHash)
    }
}
