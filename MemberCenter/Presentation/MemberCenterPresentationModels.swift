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
    let accessibilityHint: String
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
        items: [MemberCenterListItem],
        localization: AppInterfaceLocalization
    ) {
        self.id = destination
        self.title = destination.title(localization: localization)
        self.items = items
    }
}

// MARK: - MemberCenterProfileHeaderContent

nonisolated struct MemberCenterProfileHeaderContent: Sendable, Equatable {
    let displayName: String
    let subtitle: String
    let avatarURL: URL?
    let avatarImageData: Data?
    let accessibilityText: AccessibilityText

    init(
        displayName: String,
        subtitle: String,
        avatarURL: URL?,
        avatarImageData: Data? = nil,
        localization: AppInterfaceLocalization
    ) {
        self.displayName = displayName
        self.subtitle = subtitle
        self.avatarURL = avatarURL
        self.avatarImageData = avatarImageData
        self.accessibilityText = AccessibilityText(
            label: displayName,
            value: BaseDisplayTextFormatter.nonEmptyText(subtitle),
            hint: localization.string(
                "member_center.profile.accessibility_hint",
                defaultValue: "Double-tap to open Settings or sign in"
            )
        )
    }

    init(profile: AccountProfile, localization: AppInterfaceLocalization) {
        self.init(
            displayName: profile.displayName,
            subtitle: "@\(profile.username)",
            avatarURL: profile.avatarURL,
            avatarImageData: profile.avatarImageData,
            localization: localization
        )
    }

    static func guest(localization: AppInterfaceLocalization) -> MemberCenterProfileHeaderContent {
        MemberCenterProfileHeaderContent(
            displayName: localization.string("common.account.guest", defaultValue: "Guest"),
            subtitle: localization.string(
                "member_center.guest.subtitle",
                defaultValue: "Sign in to sync favorites, watchlists, and ratings"
            ),
            avatarURL: nil,
            localization: localization
        )
    }
}

// MARK: - MemberCenterGuestLoginPrompt Accessibility

extension MemberCenterGuestLoginPrompt {

    var accessibilityText: AccessibilityText {
        AccessibilityText(
            label: title,
            value: BaseDisplayTextFormatter.nonEmptyText(message),
            hint: accessibilityHint
        )
    }
}

// MARK: - MemberCenterDestination Presentation

extension MemberCenterDestination {

    func title(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .favoriteMovies:
            return localization.string("member_center.destination.favorite_movies", defaultValue: "Favorite Movies")

        case .favoriteTV:
            return localization.string("member_center.destination.favorite_tv", defaultValue: "Favorite TV Shows")

        case .watchlistMovies:
            return localization.string("member_center.destination.watchlist_movies", defaultValue: "Movie Watchlist")

        case .watchlistTV:
            return localization.string("member_center.destination.watchlist_tv", defaultValue: "TV Watchlist")

        case .ratedMovies:
            return localization.string("member_center.destination.rated_movies", defaultValue: "Rated Movies")

        case .ratedTV:
            return localization.string("member_center.destination.rated_tv", defaultValue: "Rated TV Shows")

        case .ratedEpisodes:
            return localization.string("member_center.destination.rated_episodes", defaultValue: "Rated Episodes")

        case .lists:
            return localization.string("member_center.destination.lists", defaultValue: "My Lists")
        }
    }

    func emptyTitle(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .favoriteMovies:
            return localization.string("member_center.empty.favorite_movies", defaultValue: "No Favorite Movies")

        case .favoriteTV:
            return localization.string("member_center.empty.favorite_tv", defaultValue: "No Favorite TV Shows")

        case .watchlistMovies:
            return localization.string("member_center.empty.watchlist_movies", defaultValue: "No Movies in Watchlist")

        case .watchlistTV:
            return localization.string("member_center.empty.watchlist_tv", defaultValue: "No TV Shows in Watchlist")

        case .ratedMovies:
            return localization.string("member_center.empty.rated_movies", defaultValue: "No Rated Movies")

        case .ratedTV:
            return localization.string("member_center.empty.rated_tv", defaultValue: "No Rated TV Shows")

        case .ratedEpisodes:
            return localization.string("member_center.empty.rated_episodes", defaultValue: "No Rated Episodes")

        case .lists:
            return localization.string("member_center.empty.lists", defaultValue: "No Lists")
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

    static func makeContent(
        from overview: MemberCenterOverview,
        localization: AppInterfaceLocalization
    ) -> MemberCenterContent {
        MemberCenterContent(
            profile: overview.profile,
            contentSections: overview.collections.compactMap {
                makeSection(from: $0, localization: localization)
            }
        )
    }

    static func makeGuestContent(localization: AppInterfaceLocalization) -> MemberCenterGuestContent {
        MemberCenterGuestContent(
            headerContent: .guest(localization: localization),
            loginPrompt: MemberCenterGuestLoginPrompt(
                title: localization.string(
                    "member_center.guest_prompt.title",
                    defaultValue: "Sign In to Your Account"
                ),
                message: localization.string(
                    "member_center.guest_prompt.message",
                    defaultValue: "Sign in to sync favorites, movie lists, and ratings."
                ),
                systemImageName: "person.crop.circle.badge.plus",
                actionTitle: localization.string(
                    "member_center.guest_prompt.action",
                    defaultValue: "Go to Sign In"
                ),
                accessibilityHint: localization.string(
                    "member_center.guest_prompt.accessibility_hint",
                    defaultValue: "Double-tap to sign in"
                )
            )
        )
    }

    static func makeListContent(
        from collection: AccountCollection,
        localization: AppInterfaceLocalization
    ) -> MemberCenterListContent {
        MemberCenterListContent(
            destination: collection.destination,
            items: makeItems(from: collection, localization: localization),
            currentPage: collection.page.number,
            totalPages: collection.page.totalPages,
            totalResults: collection.page.totalResults,
            isLoadingNextPage: false
        )
    }

    static func makeItems(
        from collection: AccountCollection,
        limit: Int = .max,
        localization: AppInterfaceLocalization
    ) -> [MemberCenterListItem] {
        collection.page.items
            .prefix(max(limit, 0))
            .map {
                MemberCenterListItem(
                    item: $0,
                    destination: collection.destination,
                    localization: localization
                )
            }
    }

    // MARK: - Private Methods

    private static func makeSection(
        from collection: AccountCollection,
        localization: AppInterfaceLocalization
    ) -> MemberCenterSection? {
        let items = makeItems(
            from: collection,
            limit: Configuration.previewItemLimit,
            localization: localization
        )
        guard !items.isEmpty else { return nil }

        return MemberCenterSection(
            destination: collection.destination,
            items: items,
            localization: localization
        )
    }
}
