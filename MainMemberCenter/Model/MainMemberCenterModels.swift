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
    case guest(MainMemberCenterGuestContent)
    case loaded(MainMemberCenterContent)
    case failed(ErrorMessage)
}

// MARK: - MainMemberCenterGuestContent

nonisolated struct MainMemberCenterGuestContent: Sendable, Equatable {
    let profile: MainMemberCenterProfile
    let loginPrompt: MainMemberCenterGuestLoginPrompt
}

// MARK: - MainMemberCenterGuestLoginPrompt

nonisolated struct MainMemberCenterGuestLoginPrompt: Sendable, Equatable {
    let title: String
    let message: String
    let systemImageName: String
    let actionTitle: String
}

// MARK: - MainMemberCenterContent

nonisolated struct MainMemberCenterContent: Sendable, Equatable {
    let profile: MainMemberCenterProfile
    let contentSections: [MainMemberCenterSection]

    init(
        profile: MainMemberCenterProfile,
        contentSections: [MainMemberCenterSection] = []
    ) {
        self.profile = profile
        self.contentSections = contentSections
    }
}

// MARK: - MainMemberCenterContentSnapshot

nonisolated struct MainMemberCenterContentSnapshot: Sendable {
    let profile: MainMemberCenterProfile
    let previewPages: [MainMemberCenterPreviewPage]
}

// MARK: - MainMemberCenterPreviewPage

nonisolated enum MainMemberCenterPreviewPage: Sendable {
    case favoriteMovies(MainMemberCenterFavoriteMoviePage)
    case favoriteTV(MainMemberCenterFavoriteTVPage)
    case watchlistMovies(MainMemberCenterWatchlistMoviePage)
    case watchlistTV(MainMemberCenterWatchlistTVPage)
    case ratedMovies(MainMemberCenterRatedMoviePage)
    case ratedTV(MainMemberCenterRatedTVPage)
    case ratedEpisodes(MainMemberCenterRatedEpisodePage)
    case lists(MainMemberCenterListPage)

    var destination: MainMemberCenterDestination {
        switch self {
        case .favoriteMovies:
            return .favoriteMovies

        case .favoriteTV:
            return .favoriteTV

        case .watchlistMovies:
            return .watchlistMovies

        case .watchlistTV:
            return .watchlistTV

        case .ratedMovies:
            return .ratedMovies

        case .ratedTV:
            return .ratedTV

        case .ratedEpisodes:
            return .ratedEpisodes

        case .lists:
            return .lists
        }
    }
}

// MARK: - MainMemberCenterSection

nonisolated struct MainMemberCenterSection: Sendable, Equatable, Identifiable {
    let id: MainMemberCenterDestination
    let title: String
    let items: [MainMemberCenterListItem]

    init(
        destination: MainMemberCenterDestination,
        items: [MainMemberCenterListItem]
    ) {
        self.id = destination
        self.title = destination.title
        self.items = items
    }
}

// MARK: - MainMemberCenterProfile

nonisolated struct MainMemberCenterProfile: Sendable, Equatable {
    let id: Int
    let displayName: String
    let username: String
    let subtitle: String
    let avatarURL: URL?
    let languageCode: String
    let regionCode: String
    let includesAdultContent: Bool

    init(
        id: Int,
        displayName: String,
        username: String,
        subtitle: String,
        avatarURL: URL?,
        languageCode: String,
        regionCode: String,
        includesAdultContent: Bool
    ) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.subtitle = subtitle
        self.avatarURL = avatarURL
        self.languageCode = languageCode
        self.regionCode = regionCode
        self.includesAdultContent = includesAdultContent
    }

    init(account: Account) {
        self.id = account.id
        self.displayName = account.name?.isEmpty == false ? account.name ?? account.username : account.username
        self.username = account.username
        self.subtitle = "@\(account.username)"
        self.avatarURL = Self.makeAvatarURL(from: account)
        self.languageCode = account.iso_639_1
        self.regionCode = account.iso_3166_1
        self.includesAdultContent = account.include_adult
    }

    static let guest = MainMemberCenterProfile(
        id: 0,
        displayName: "訪客",
        username: "guest",
        subtitle: "登入後同步收藏、待看與評分",
        avatarURL: nil,
        languageCode: "",
        regionCode: "",
        includesAdultContent: false
    )

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
