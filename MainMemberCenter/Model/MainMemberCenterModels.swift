//
//  MainMemberCenterModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import Foundation

// MARK: - MainMemberCenterViewState

nonisolated enum MainMemberCenterViewState: Equatable {
    case idle
    case loading
    case loaded(MainMemberCenterContent)
    case failed(ErrorMessage)
}

// MARK: - MainMemberCenterContent

nonisolated struct MainMemberCenterContent: Sendable, Equatable {
    let profile: MainMemberCenterProfile
    let menuItems: [MainMemberCenterMenuItem]

    init(profile: MainMemberCenterProfile) {
        self.profile = profile
        self.menuItems = MainMemberCenterDestination.allCases.map(MainMemberCenterMenuItem.init(destination:))
    }
}

// MARK: - MainMemberCenterProfile

nonisolated struct MainMemberCenterProfile: Sendable, Equatable {
    let id: Int
    let displayName: String
    let username: String
    let avatarURL: URL?
    let languageCode: String
    let regionCode: String
    let includesAdultContent: Bool

    init(account: Account) {
        self.id = account.id
        self.displayName = account.name?.isEmpty == false ? account.name ?? account.username : account.username
        self.username = account.username
        self.avatarURL = Self.makeAvatarURL(from: account)
        self.languageCode = account.iso_639_1
        self.regionCode = account.iso_3166_1
        self.includesAdultContent = account.include_adult
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

// MARK: - MainMemberCenterDestination

nonisolated enum MainMemberCenterDestination: String, Sendable, Equatable, CaseIterable, Identifiable {
    case favoriteMovies
    case favoriteTV
    case watchlistMovies
    case watchlistTV
    case ratedMovies
    case ratedTV
    case ratedEpisodes
    case lists

    var id: Self { self }

    var title: String {
        switch self {
        case .favoriteMovies:
            return "收藏電影"

        case .favoriteTV:
            return "收藏影集"

        case .watchlistMovies:
            return "待看電影"

        case .watchlistTV:
            return "待看影集"

        case .ratedMovies:
            return "評分電影"

        case .ratedTV:
            return "評分影集"

        case .ratedEpisodes:
            return "評分集數"

        case .lists:
            return "我的片單"
        }
    }

    var systemImageName: String {
        switch self {
        case .favoriteMovies, .favoriteTV:
            return "heart"

        case .watchlistMovies, .watchlistTV:
            return "bookmark"

        case .ratedMovies, .ratedTV, .ratedEpisodes:
            return "star"

        case .lists:
            return "list.bullet.rectangle"
        }
    }
}

// MARK: - MainMemberCenterMenuItem

nonisolated struct MainMemberCenterMenuItem: Sendable, Equatable, Identifiable {
    let id: MainMemberCenterDestination
    let title: String
    let systemImageName: String

    init(destination: MainMemberCenterDestination) {
        self.id = destination
        self.title = destination.title
        self.systemImageName = destination.systemImageName
    }
}
