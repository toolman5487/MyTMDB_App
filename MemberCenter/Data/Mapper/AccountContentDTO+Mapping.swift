//
//  AccountContentDTO+Mapping.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
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

// MARK: - RatedMediaDTO Mapping

extension RatedMediaDTO {

    func mapped(kind: MediaKind) -> RatedMedia {
        RatedMedia(
            summary: MediaSummary(
                id: id,
                title: title,
                overview: overview,
                posterPath: posterPath,
                backdropPath: backdropPath,
                releaseDate: CalendarDayParsing.calendarDay(from: releaseDate),
                voteAverage: voteAverage,
                voteCount: voteCount,
                popularity: popularity,
                genreIDs: []
            ),
            kind: kind,
            rating: rating
        )
    }
}

// MARK: - RatedEpisodeDTO Mapping

extension RatedEpisodeDTO {

    func mapped() -> RatedEpisode {
        RatedEpisode(
            id: id,
            seriesID: showID,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            name: name,
            overview: overview,
            airDate: CalendarDayParsing.calendarDay(from: airDate),
            stillPath: stillPath,
            voteAverage: voteAverage,
            voteCount: voteCount,
            rating: rating
        )
    }
}

// MARK: - AccountListDTO Mapping

extension AccountListDTO {

    func mapped() -> AccountList {
        AccountList(
            id: id,
            name: name,
            description: description,
            languageCode: languageCode,
            listType: listType,
            itemCount: itemCount,
            favoriteCount: favoriteCount,
            posterPath: posterPath
        )
    }
}
