//
//  MainSearchPresentationModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/23.
//

import Foundation

// MARK: - MainSearchMediaType Presentation

extension MainSearchMediaType {

    func title(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .movie:
            return localization.string("common.media.movie", defaultValue: "Movie")

        case .tv:
            return localization.string("common.media.tv_series", defaultValue: "TV Show")

        case .person:
            return localization.string("common.media.person", defaultValue: "Person")
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

    func title(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .all:
            return localization.string("common.filter.all", defaultValue: "All")

        case .movie:
            return MainSearchMediaType.movie.title(localization: localization)

        case .tv:
            return MainSearchMediaType.tv.title(localization: localization)

        case .person:
            return MainSearchMediaType.person.title(localization: localization)
        }
    }

    func emptyResultsTitle(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .all:
            return localization.string("main_search.filtered_empty.all.title", defaultValue: "No Results")

        case .movie:
            return localization.string("main_search.filtered_empty.movie.title", defaultValue: "No Movie Results")

        case .tv:
            return localization.string("main_search.filtered_empty.tv.title", defaultValue: "No TV Show Results")

        case .person:
            return localization.string("main_search.filtered_empty.person.title", defaultValue: "No People Results")
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

    func appending(
        page: Page<MainSearchResult>,
        localization: AppInterfaceLocalization
    ) -> MainSearchDailyTrendingContent {
        let existingIDs = Set(items.map(\.id))
        let newItems = MainSearchContent.uniqueResults(
            page.items.map { MainSearchResultItem(result: $0, localization: localization) }
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

    func filters(localization: AppInterfaceLocalization) -> [MainSearchFilterItem] {
        MainSearchFilter.allCases.map { filter in
            MainSearchFilterItem(
                filter: filter,
                isSelected: filter == selectedFilter,
                localization: localization
            )
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

    func appending(
        page: Page<MainSearchResult>,
        localization: AppInterfaceLocalization
    ) -> MainSearchContent {
        MainSearchContent(
            keyword: keyword,
            allResults: Self.uniqueResults(
                allResults + page.items.map {
                    MainSearchResultItem(result: $0, localization: localization)
                }
            ),
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
    let title: String
    let isSelected: Bool

    init(
        filter: MainSearchFilter,
        isSelected: Bool,
        localization: AppInterfaceLocalization
    ) {
        self.filter = filter
        self.title = filter.title(localization: localization)
        self.isSelected = isSelected
    }

    var id: String {
        filter.id
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
    let accessibilityText: AccessibilityText

    init(
        result: MainSearchResult,
        localization: AppInterfaceLocalization
    ) {
        let title = Self.makeTitle(result.title, localization: localization)
        let subtitle = Self.makeSubtitle(for: result, localization: localization)
        self.id = "\(result.mediaType.rawValue)-\(result.id)"
        self.sourceID = result.id
        self.mediaType = result.mediaType
        self.title = title
        self.subtitle = subtitle
        self.imageURL = Self.makeImageURL(for: result)
        self.popularity = result.popularity
        self.accessibilityText = Self.makeAccessibilityText(
            title: title,
            subtitle: subtitle,
            mediaType: result.mediaType,
            localization: localization
        )
    }

    init(
        person: MainSearchPopularPerson,
        localization: AppInterfaceLocalization
    ) {
        let title = Self.makeTitle(person.name, localization: localization)
        let subtitle = BaseDisplayTextFormatter.nonEmptyText(person.knownForDepartment)
        self.id = "\(MainSearchMediaType.person.rawValue)-\(person.id)"
        self.sourceID = person.id
        self.mediaType = .person
        self.title = title
        self.subtitle = subtitle
        self.imageURL = person.profilePath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w185)
        }
        self.popularity = person.popularity
        self.accessibilityText = Self.makeAccessibilityText(
            title: title,
            subtitle: subtitle,
            mediaType: .person,
            localization: localization
        )
    }

    private static func makeTitle(
        _ title: String,
        localization: AppInterfaceLocalization
    ) -> String {
        guard let title = BaseDisplayTextFormatter.nonEmptyText(title) else {
            return localization.string("common.fallback.untitled", defaultValue: "Untitled")
        }

        return BaseFormatter.SimplifiedChineseTextMapper.traditionalChinese(from: title)
    }

    private static func makeSubtitle(
        for result: MainSearchResult,
        localization: AppInterfaceLocalization
    ) -> String? {
        switch result.mediaType {
        case .movie, .tv:
            return BaseDisplayTextFormatter.metadata([
                result.primaryDate.map { String($0.year) },
                BaseDisplayTextFormatter.ratingText(
                    result.voteAverage,
                    localization: localization
                )
            ])

        case .person:
            return BaseDisplayTextFormatter.nonEmptyText(result.knownForDepartment)
        }
    }

    private static func makeImageURL(for result: MainSearchResult) -> URL? {
        switch result.mediaType {
        case .movie, .tv:
            return result.posterPath.flatMap {
                TMDBResourceURL.image(path: $0, size: .w185)
            }

        case .person:
            return result.profilePath.flatMap {
                TMDBResourceURL.image(path: $0, size: .w185)
            }
        }
    }

    private static func makeAccessibilityText(
        title: String,
        subtitle: String?,
        mediaType: MainSearchMediaType,
        localization: AppInterfaceLocalization
    ) -> AccessibilityText {
        AccessibilityText(
            label: title,
            value: BaseDisplayTextFormatter.metadata([
                mediaType.title(localization: localization),
                subtitle
            ]),
            hint: accessibilityHint(
                for: mediaType,
                localization: localization
            )
        )
    }

    private static func accessibilityHint(
        for mediaType: MainSearchMediaType,
        localization: AppInterfaceLocalization
    ) -> String {
        switch mediaType {
        case .movie:
            return localization.string(
                "common.accessibility.open_movie_detail.hint",
                defaultValue: "Double-tap to open movie details"
            )

        case .tv:
            return localization.string(
                "common.accessibility.open_tv_detail.hint",
                defaultValue: "Double-tap to open TV show details"
            )

        case .person:
            return localization.string(
                "common.accessibility.open_person_detail.hint",
                defaultValue: "Double-tap to open person details"
            )
        }
    }
}
