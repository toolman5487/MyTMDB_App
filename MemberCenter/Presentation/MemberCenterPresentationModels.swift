//
//  MemberCenterPresentationModels.swift
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
    let accountID: Int
    let sessionID: String
}

// MARK: - MemberCenterListRoute

nonisolated struct MemberCenterListRoute: Sendable, Equatable {
    let destination: MemberCenterDestination
    let accountID: Int
    let sessionID: String
}

// MARK: - MemberCenterGuestContent

nonisolated struct MemberCenterGuestContent: Sendable, Equatable {
    let headerContent: MemberCenterProfileHeaderContent
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
    let profile: AccountProfile
    let contentSections: [MemberCenterSection]

    init(
        profile: AccountProfile,
        contentSections: [MemberCenterSection] = []
    ) {
        self.profile = profile
        self.contentSections = contentSections
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

    init(profile: AccountProfile) {
        self.init(
            displayName: profile.displayName,
            subtitle: "@\(profile.username)",
            avatarURL: profile.avatarURL,
            avatarImageData: profile.avatarImageData
        )
    }

    static let guest = MemberCenterProfileHeaderContent(
        displayName: "訪客",
        subtitle: "登入後同步收藏、待看與評分",
        avatarURL: nil
    )
}

// MARK: - MemberCenterProfileHeaderContent Accessibility

extension MemberCenterProfileHeaderContent {

    var accessibilityText: AccessibilityText {
        AccessibilityText(
            label: displayName,
            value: BaseDisplayTextFormatter.nonEmptyText(subtitle),
            hint: "點兩下開啟設定或登入"
        )
    }
}

// MARK: - MemberCenterGuestLoginPrompt Accessibility

extension MemberCenterGuestLoginPrompt {

    var accessibilityText: AccessibilityText {
        AccessibilityText(
            label: title,
            value: BaseDisplayTextFormatter.nonEmptyText(message),
            hint: "點兩下\(actionTitle)"
        )
    }
}

// MARK: - MemberCenterDestination Presentation

extension MemberCenterDestination {

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

// MARK: - MemberCenterPresentationBuilder

nonisolated enum MemberCenterPresentationBuilder {

    private enum Configuration {
        static let previewItemLimit = 10
    }

    static func makeContent(from overview: MemberCenterOverview) -> MemberCenterContent {
        MemberCenterContent(
            profile: overview.profile,
            contentSections: overview.collections.compactMap(makeSection)
        )
    }

    static func makeGuestContent() -> MemberCenterGuestContent {
        MemberCenterGuestContent(
            headerContent: .guest,
            loginPrompt: MemberCenterGuestLoginPrompt(
                title: "登入帳號",
                message: "登入後同步收藏、電影清單、評分內容。",
                systemImageName: "person.crop.circle.badge.plus",
                actionTitle: "前往登入"
            )
        )
    }

    static func makeListContent(from collection: AccountCollection) -> MemberCenterListContent {
        MemberCenterListContent(
            destination: collection.destination,
            items: makeItems(from: collection),
            currentPage: collection.page.number,
            totalPages: collection.page.totalPages,
            totalResults: collection.page.totalResults,
            isLoadingNextPage: false
        )
    }

    static func makeItems(
        from collection: AccountCollection,
        limit: Int = .max
    ) -> [MemberCenterListItem] {
        collection.page.items
            .prefix(max(limit, 0))
            .map { MemberCenterListItem(item: $0, destination: collection.destination) }
    }

    // MARK: - Private Methods

    private static func makeSection(from collection: AccountCollection) -> MemberCenterSection? {
        let items = makeItems(from: collection, limit: Configuration.previewItemLimit)
        guard !items.isEmpty else { return nil }

        return MemberCenterSection(
            destination: collection.destination,
            items: items
        )
    }
}
