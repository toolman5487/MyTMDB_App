//
//  MemberCenterModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import Foundation

// MARK: - MemberCenterViewState

nonisolated enum MemberCenterViewState: Equatable {
    case idle
    case loading
    case guest(MemberCenterGuestContent)
    case empty(MemberCenterContent)
    case loaded(MemberCenterContent)
    case failed(ErrorMessage)
}

// MARK: - MemberCenterDisplaySection

nonisolated enum MemberCenterDisplaySection: Sendable, Equatable {
    case guestLogin(MemberCenterGuestLoginPrompt)
    case content(MemberCenterSection)
}

// MARK: - MemberCenterProfileAction

nonisolated enum MemberCenterProfileAction: Sendable, Equatable {
    case settings
    case login
}

// MARK: - MemberCenterAccountContext

nonisolated struct MemberCenterAccountContext: Sendable, Equatable {
    let accountId: Int
    let sessionId: String
}

// MARK: - MemberCenterListRoute

nonisolated struct MemberCenterListRoute: Sendable, Equatable {
    let destination: MemberCenterDestination
    let accountId: Int
    let sessionId: String
}

// MARK: - MemberCenterGuestContent

nonisolated struct MemberCenterGuestContent: Sendable, Equatable {
    let profile: MemberCenterProfile
    let loginPrompt: MemberCenterGuestLoginPrompt
}

// MARK: - MemberCenterGuestLoginPrompt

nonisolated struct MemberCenterGuestLoginPrompt: Sendable, Equatable {
    let title: String
    let message: String
    let systemImageName: String
    let actionTitle: String
}

// MARK: - MemberCenterContent

nonisolated struct MemberCenterContent: Sendable, Equatable {
    let profile: MemberCenterProfile
    let contentSections: [MemberCenterSection]

    init(
        profile: MemberCenterProfile,
        contentSections: [MemberCenterSection] = []
    ) {
        self.profile = profile
        self.contentSections = contentSections
    }
}

// MARK: - MemberCenterProfileHeaderContent

nonisolated struct MemberCenterProfileHeaderContent: Sendable, Equatable {
    let displayName: String
    let subtitle: String
    let avatarURL: URL?
    let avatarImageData: Data?

    init(
        displayName: String,
        subtitle: String,
        avatarURL: URL?,
        avatarImageData: Data? = nil
    ) {
        self.displayName = displayName
        self.subtitle = subtitle
        self.avatarURL = avatarURL
        self.avatarImageData = avatarImageData
    }
}

// MARK: - MemberCenterContentSnapshot

nonisolated struct MemberCenterContentSnapshot: Sendable {
    let profile: MemberCenterProfile
    let previewPages: [MemberCenterPreviewPage]
}

// MARK: - MemberCenterPreviewPage

nonisolated enum MemberCenterPreviewPage: Sendable {
    case favoriteMovies(MemberCenterFavoriteMoviePage)
    case favoriteTV(MemberCenterFavoriteTVPage)
    case watchlistMovies(MemberCenterWatchlistMoviePage)
    case watchlistTV(MemberCenterWatchlistTVPage)
    case ratedMovies(MemberCenterRatedMoviePage)
    case ratedTV(MemberCenterRatedTVPage)
    case ratedEpisodes(MemberCenterRatedEpisodePage)
    case lists(MemberCenterListPage)

    var destination: MemberCenterDestination {
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

// MARK: - MemberCenterSection

nonisolated struct MemberCenterSection: Sendable, Equatable, Identifiable {
    let id: MemberCenterDestination
    let title: String
    let items: [MemberCenterListItem]

    init(
        destination: MemberCenterDestination,
        items: [MemberCenterListItem]
    ) {
        self.id = destination
        self.title = destination.title
        self.items = items
    }
}

// MARK: - MemberCenterProfile

nonisolated struct MemberCenterProfile: Sendable, Equatable {
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

    init?(storedProfile: StoredUserProfile) {
        guard let accountId = storedProfile.accountId else { return nil }

        self.id = accountId
        self.displayName = storedProfile.displayName
        self.username = storedProfile.username
        self.subtitle = "@\(storedProfile.username)"
        self.avatarURL = storedProfile.avatarURL
        self.languageCode = storedProfile.languageCode ?? ""
        self.regionCode = storedProfile.regionCode ?? ""
        self.includesAdultContent = storedProfile.includesAdultContent ?? false
    }

    static let guest = MemberCenterProfile(
        id: 0,
        displayName: "訪客",
        username: "guest",
        subtitle: "登入後同步收藏、待看與評分",
        avatarURL: nil,
        languageCode: "",
        regionCode: "",
        includesAdultContent: false
    )

    var headerContent: MemberCenterProfileHeaderContent {
        MemberCenterProfileHeaderContent(
            displayName: displayName,
            subtitle: subtitle,
            avatarURL: avatarURL
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

// MARK: - MemberCenterDestination

nonisolated enum MemberCenterDestination: String, Sendable, Equatable, CaseIterable, Identifiable {
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
