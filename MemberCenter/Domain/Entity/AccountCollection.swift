//
//  AccountCollection.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - RatedMedia

/// 已評分的電影或影集：公開資料加上本帳號給的分數。
nonisolated struct RatedMedia: Sendable, Equatable, Identifiable {
    let summary: MediaSummary
    let kind: MediaKind
    let rating: Double

    var id: Int { summary.id }
}

// MARK: - RatedEpisode

nonisolated struct RatedEpisode: Sendable, Equatable, Identifiable {
    let id: Int
    let seriesID: Int
    let seasonNumber: Int
    let episodeNumber: Int
    let name: String
    let overview: String
    let airDate: CalendarDay?
    let stillPath: String?
    let voteAverage: Double
    let voteCount: Int
    let rating: Double
}

// MARK: - AccountList

nonisolated struct AccountList: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let languageCode: String
    let listType: String
    let itemCount: Int
    let favoriteCount: Int
    let posterPath: String?

    func replacingMissingPosterPath(with fallbackPosterPath: String?) -> AccountList {
        guard posterPath == nil, let fallbackPosterPath else { return self }

        return AccountList(
            id: id,
            name: name,
            description: description,
            languageCode: languageCode,
            listType: listType,
            itemCount: itemCount,
            favoriteCount: favoriteCount,
            posterPath: fallbackPosterPath
        )
    }
}

// MARK: - AccountCollectionItem

/// 八種 destination 共用的項目型別；destination 決定實際會出現哪一種 case。
nonisolated enum AccountCollectionItem: Sendable, Equatable {
    case media(MediaSummary, kind: MediaKind)
    case ratedMedia(RatedMedia)
    case ratedEpisode(RatedEpisode)
    case list(AccountList)
}

// MARK: - AccountCollection

nonisolated struct AccountCollection: Sendable, Equatable {
    let destination: MemberCenterDestination
    let page: Page<AccountCollectionItem>
}

// MARK: - MemberCenterOverview

nonisolated struct MemberCenterOverview: Sendable, Equatable {
    let profile: AccountProfile
    let collections: [AccountCollection]
}
