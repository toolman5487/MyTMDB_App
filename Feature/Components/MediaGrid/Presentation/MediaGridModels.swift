//
//  MediaGridModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - MediaGridItem

nonisolated struct MediaGridItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterURL: URL?
    let dateText: String
    let scoreText: String

    init(
        summary: MediaSummary,
        localization: AppInterfaceLocalization
    ) {
        self.id = summary.id
        self.title = BaseDisplayTextFormatter.text(
            summary.title,
            fallback: localization.string("common.fallback.untitled", defaultValue: "Untitled")
        )
        self.overview = BaseDisplayTextFormatter.overview(
            summary.overview,
            localization: localization
        )
        self.posterURL = summary.posterPath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w185)
        }
        self.dateText = BaseDisplayTextFormatter.announcedText(
            BaseDisplayTextFormatter.isoDayText(from: summary.releaseDate),
            localization: localization
        )
        self.scoreText = BaseDisplayTextFormatter.decimal(summary.voteAverage)
    }

    func ratingText(localization: AppInterfaceLocalization) -> String {
        BaseDisplayTextFormatter.ratingText(scoreText, localization: localization) as String
    }
}

// MARK: - MediaGridPaginationState

nonisolated struct MediaGridPaginationState: Sendable, Equatable {
    private static let nextPageThreshold = 4

    let currentPage: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool

    init(
        currentPage: Int,
        totalPages: Int,
        totalResults: Int,
        isLoadingNextPage: Bool = false
    ) {
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.totalResults = totalResults
        self.isLoadingNextPage = isLoadingNextPage
    }

    init<Element>(page: Page<Element>) {
        self.init(
            currentPage: page.number,
            totalPages: page.totalPages,
            totalResults: page.totalResults
        )
    }

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }

    var nextPage: Int {
        currentPage + 1
    }

    func updatingLoadingNextPage(_ isLoading: Bool) -> MediaGridPaginationState {
        MediaGridPaginationState(
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoading
        )
    }

    static func shouldLoadNextPage(currentIndex: Int, itemCount: Int) -> Bool {
        let thresholdIndex = max(itemCount - nextPageThreshold, 0)
        return currentIndex >= thresholdIndex
    }

    func shouldLoadNextPage<Item: Identifiable>(
        currentItemID: Item.ID,
        items: [Item]
    ) -> Bool {
        guard canLoadNextPage,
              !isLoadingNextPage,
              let currentIndex = items.firstIndex(where: { $0.id == currentItemID }) else {
            return false
        }

        return Self.shouldLoadNextPage(
            currentIndex: currentIndex,
            itemCount: items.count
        )
    }
}

// MARK: - AppSortMenuOption

nonisolated protocol AppSortMenuOption: Hashable, CaseIterable {
    func title(localization: AppInterfaceLocalization) -> String
}

// MARK: - MediaSortOrder Presentation

extension MediaSortOrder: Identifiable, AppSortMenuOption {

    public var id: MediaSortOrder {
        self
    }

    func title(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .popularity:
            return localization.string("sort.popularity", defaultValue: "Most Popular")

        case .ratingHighToLow:
            return localization.string("sort.rating_high_to_low", defaultValue: "Highest Rated")

        case .ratingLowToHigh:
            return localization.string("sort.rating_low_to_high", defaultValue: "Lowest Rated")

        case .newestDate:
            return localization.string("sort.newest", defaultValue: "Newest")

        case .oldestDate:
            return localization.string("sort.oldest", defaultValue: "Oldest")

        case .titleAscending:
            return localization.string("sort.title_ascending", defaultValue: "Title (A → Z)")

        case .titleDescending:
            return localization.string("sort.title_descending", defaultValue: "Title (Z → A)")
        }
    }
}
