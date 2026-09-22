//
//  ReviewPresentationModels.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation

// MARK: - ReviewFilter Presentation

extension ReviewFilter {

    func title(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .all:
            return localization.string("common.filter.all", defaultValue: "All")

        case .rated:
            return localization.string("review.filter.rated", defaultValue: "Rated")

        case .unrated:
            return localization.string("review.filter.unrated", defaultValue: "Unrated")

        case .latest:
            return localization.string("review.filter.latest", defaultValue: "Newest Reviews")

        case .oldest:
            return localization.string("review.filter.oldest", defaultValue: "Oldest Reviews")
        }
    }
}

// MARK: - ReviewListPresentation

nonisolated struct ReviewListPresentation: Sendable, Equatable {
    let filters: [ReviewFilterItem]
    let reviews: [ReviewItem]
    let pagination: MediaGridPaginationState

    var canLoadNextPage: Bool {
        pagination.canLoadNextPage
    }

    var isLoadingNextPage: Bool {
        pagination.isLoadingNextPage
    }
}

// MARK: - ReviewFilterItem

nonisolated struct ReviewFilterItem: Sendable, Equatable, Identifiable {
    let id: ReviewFilter
    let title: String
    let isSelected: Bool

    init(
        filter: ReviewFilter,
        selectedFilter: ReviewFilter,
        localization: AppInterfaceLocalization
    ) {
        self.id = filter
        self.title = filter.title(localization: localization)
        self.isSelected = filter == selectedFilter
    }
}

// MARK: - ReviewItem

nonisolated struct ReviewItem: Sendable, Equatable, Identifiable {
    let id: String
    let authorText: String
    let ratingText: String?
    let updatedDateText: String?
    let content: String
    let avatarURL: URL?

    init(review: Review, localization: AppInterfaceLocalization) {
        self.id = review.id
        self.authorText = BaseDisplayTextFormatter.text(
            review.authorName,
            fallback: localization.string(
                "review.author.anonymous",
                defaultValue: "Anonymous User"
            )
        )
        self.ratingText = BaseDisplayTextFormatter.score(review.rating)
        self.updatedDateText = BaseDisplayTextFormatter.displayDate(
            from: review.updatedAt,
            localization: localization
        )
        self.content = review.content
        self.avatarURL = Self.makeAvatarURL(from: review.avatarPath)
    }

    private static func makeAvatarURL(from path: String?) -> URL? {
        guard let path else { return nil }

        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else { return nil }

        if trimmedPath.hasPrefix("/https://") || trimmedPath.hasPrefix("/http://") {
            return URL(string: String(trimmedPath.dropFirst()))
        }

        return TMDBResourceURL.image(path: trimmedPath, size: .w185)
    }
}
