//
//  MainSearchPresentationModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/23.
//

import Foundation

// MARK: - MainSearchMediaType Presentation

extension MainSearchMediaType {

    var title: String {
        switch self {
        case .movie:
            return "電影"

        case .tv:
            return "劇集"

        case .person:
            return "人物"
        }
    }
}

// MARK: - MainSearchFilter

nonisolated enum MainSearchFilter: String, CaseIterable, Sendable, Equatable, Identifiable {
    case all
    case movie
    case tv
    case person

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .all:
            return "全部"

        case .movie:
            return MainSearchMediaType.movie.title

        case .tv:
            return MainSearchMediaType.tv.title

        case .person:
            return MainSearchMediaType.person.title
        }
    }

    var mediaType: MainSearchMediaType? {
        switch self {
        case .all:
            return nil

        case .movie:
            return .movie

        case .tv:
            return .tv

        case .person:
            return .person
        }
    }
}

// MARK: - MainSearchDailyTrendingContent

nonisolated struct MainSearchDailyTrendingContent: Sendable, Equatable {
    let recentSearchEntries: [SearchHistoryEntry]
    let popularPeople: [MainSearchResultItem]
    let items: [MainSearchResultItem]
    let currentPage: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }

    func updatingLoadingNextPage(_ isLoading: Bool) -> MainSearchDailyTrendingContent {
        MainSearchDailyTrendingContent(
            recentSearchEntries: recentSearchEntries,
            popularPeople: popularPeople,
            items: items,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoading
        )
    }

    func appending(page: Page<MainSearchResult>) -> MainSearchDailyTrendingContent {
        let existingIDs = Set(items.map(\.id))
        let newItems = MainSearchContent.uniqueResults(
            page.items.map(MainSearchResultItem.init(result:))
        )
        .filter { !existingIDs.contains($0.id) }
        .shuffled()

        return MainSearchDailyTrendingContent(
            recentSearchEntries: recentSearchEntries,
            popularPeople: popularPeople,
            items: items + newItems,
            currentPage: page.number,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false
        )
    }

    func updatingRecentSearchEntries(_ entries: [SearchHistoryEntry]) -> MainSearchDailyTrendingContent {
        MainSearchDailyTrendingContent(
            recentSearchEntries: entries,
            popularPeople: popularPeople,
            items: items,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoadingNextPage
        )
    }
}

// MARK: - MainSearchContent

nonisolated struct MainSearchContent: Sendable, Equatable {
    let keyword: String
    let allResults: [MainSearchResultItem]
    let selectedFilter: MainSearchFilter
    let currentPage: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool

    var results: [MainSearchResultItem] {
        guard let mediaType = selectedFilter.mediaType else {
            return allResults
        }

        return allResults.filter { $0.mediaType == mediaType }
    }

    var filters: [MainSearchFilterItem] {
        MainSearchFilter.allCases.map { filter in
            MainSearchFilterItem(filter: filter, isSelected: filter == selectedFilter)
        }
    }

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }

    func updatingLoadingNextPage(_ isLoading: Bool) -> MainSearchContent {
        MainSearchContent(
            keyword: keyword,
            allResults: allResults,
            selectedFilter: selectedFilter,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoading
        )
    }

    func appending(page: Page<MainSearchResult>) -> MainSearchContent {
        MainSearchContent(
            keyword: keyword,
            allResults: Self.uniqueResults(allResults + page.items.map(MainSearchResultItem.init(result:))),
            selectedFilter: selectedFilter,
            currentPage: page.number,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false
        )
    }

    func selectingFilter(_ filter: MainSearchFilter) -> MainSearchContent {
        MainSearchContent(
            keyword: keyword,
            allResults: allResults,
            selectedFilter: filter,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoadingNextPage
        )
    }

    static func uniqueResults(_ results: [MainSearchResultItem]) -> [MainSearchResultItem] {
        var seenIDs = Set<String>()
        return results.filter { result in
            seenIDs.insert(result.id).inserted
        }
    }
}

// MARK: - MainSearchFilterItem

nonisolated struct MainSearchFilterItem: Sendable, Equatable, Identifiable {
    let filter: MainSearchFilter
    let isSelected: Bool

    var id: String {
        filter.id
    }

    var title: String {
        filter.title
    }
}

// MARK: - MainSearchResultItem

nonisolated struct MainSearchResultItem: Sendable, Equatable, Identifiable {
    let id: String
    let sourceID: Int
    let mediaType: MainSearchMediaType
    let title: String
    let subtitle: String?
    let imageURL: URL?
    let popularity: Double

    init(result: MainSearchResult) {
        self.id = "\(result.mediaType.rawValue)-\(result.id)"
        self.sourceID = result.id
        self.mediaType = result.mediaType
        self.title = Self.makeTitle(result.title)
        self.subtitle = Self.makeSubtitle(for: result)
        self.imageURL = Self.makeImageURL(for: result)
        self.popularity = result.popularity
    }

    init(person: MainSearchPopularPerson) {
        self.id = "\(MainSearchMediaType.person.rawValue)-\(person.id)"
        self.sourceID = person.id
        self.mediaType = .person
        self.title = Self.makeTitle(person.name)
        self.subtitle = BaseDisplayTextFormatter.nonEmptyText(person.knownForDepartment)
        self.imageURL = person.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
        self.popularity = person.popularity
    }

    private static func makeTitle(_ title: String) -> String {
        guard let title = BaseDisplayTextFormatter.nonEmptyText(title) else {
            return "未命名"
        }

        return BaseFormatter.SimplifiedChineseTextMapper.traditionalChinese(from: title)
    }

    private static func makeSubtitle(for result: MainSearchResult) -> String? {
        switch result.mediaType {
        case .movie, .tv:
            return BaseDisplayTextFormatter.metadata([
                result.primaryDate.map { String($0.year) },
                BaseDisplayTextFormatter.ratingText(result.voteAverage)
            ])

        case .person:
            return BaseDisplayTextFormatter.nonEmptyText(result.knownForDepartment)
        }
    }

    private static func makeImageURL(for result: MainSearchResult) -> URL? {
        switch result.mediaType {
        case .movie, .tv:
            return result.posterPath.flatMap {
                APIConfig.tmdbImageURL(path: $0, size: .w185)
            }

        case .person:
            return result.profilePath.flatMap {
                APIConfig.tmdbImageURL(path: $0, size: .w185)
            }
        }
    }
}

// MARK: - Accessibility

extension MainSearchResultItem {

    var accessibilityText: AccessibilityText {
        AccessibilityText(
            label: title,
            value: BaseDisplayTextFormatter.metadata([
                mediaType.title,
                subtitle
            ]),
            hint: accessibilityHint
        )
    }

    private var accessibilityHint: String {
        switch mediaType {
        case .movie:
            return "點兩下開啟電影詳細資料"

        case .tv:
            return "點兩下開啟劇集詳細資料"

        case .person:
            return "點兩下開啟人物詳細資料"
        }
    }
}
