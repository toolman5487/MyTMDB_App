//
//  MainMediaListPresentationModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import Foundation

// MARK: - MainMediaGenreItem

nonisolated struct MainMediaGenreItem: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let isSelected: Bool

    init(
        genre: MediaGenre,
        isSelected: Bool
    ) {
        self.id = genre.id
        self.name = BaseFormatter.SimplifiedChineseTextMapper.traditionalChinese(from: genre.name)
        self.isSelected = isSelected
    }
}

// MARK: - MainMediaListContent

nonisolated struct MainMediaListContent: Sendable, Equatable {
    let genres: [MainMediaGenreItem]
    let selectedGenre: MainMediaGenreItem
    let items: [MediaGridItem]
    private(set) var pagination: MediaGridPaginationState
    let selectedSortOption: MediaSortOrder?

    func updatingLoadingNextPage(_ isLoading: Bool) -> MainMediaListContent {
        var content = self
        content.pagination = pagination.updatingLoadingNextPage(isLoading)
        return content
    }

    func appending(
        page: Page<MediaSummary>,
        localization: AppInterfaceLocalization
    ) -> MainMediaListContent {
        MainMediaListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            items: items + page.items.map {
                MediaGridItem(summary: $0, localization: localization)
            },
            pagination: MediaGridPaginationState(page: page),
            selectedSortOption: selectedSortOption
        )
    }

    func updatingSortOption(_ option: MediaSortOrder) -> MainMediaListContent {
        MainMediaListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            items: items,
            pagination: pagination,
            selectedSortOption: option
        )
    }
}

// MARK: - MainMediaListPresentationBuilder

nonisolated enum MainMediaListPresentationBuilder {

    static func makeContent(
        genres: [MediaGenre],
        selectedGenre: MediaGenre,
        page: Page<MediaSummary>,
        selectedSortOption: MediaSortOrder,
        localization: AppInterfaceLocalization
    ) -> MainMediaListContent {
        MainMediaListContent(
            genres: makeGenreItems(genres: genres, selectedGenre: selectedGenre),
            selectedGenre: MainMediaGenreItem(
                genre: selectedGenre,
                isSelected: true
            ),
            items: page.items.map {
                MediaGridItem(summary: $0, localization: localization)
            },
            pagination: MediaGridPaginationState(page: page),
            selectedSortOption: selectedSortOption
        )
    }

    static func makePreviewContent(
        genres: [MediaGenre],
        selectedGenre: MediaGenre,
        selectedSortOption: MediaSortOrder
    ) -> MainMediaListContent {
        MainMediaListContent(
            genres: makeGenreItems(genres: genres, selectedGenre: selectedGenre),
            selectedGenre: MainMediaGenreItem(
                genre: selectedGenre,
                isSelected: true
            ),
            items: [],
            pagination: MediaGridPaginationState(
                currentPage: 0,
                totalPages: 0,
                totalResults: 0
            ),
            selectedSortOption: selectedSortOption
        )
    }

    // MARK: - Private Methods

    private static func makeGenreItems(
        genres: [MediaGenre],
        selectedGenre: MediaGenre
    ) -> [MainMediaGenreItem] {
        genres.map { genre in
            MainMediaGenreItem(
                genre: genre,
                isSelected: genre.id == selectedGenre.id
            )
        }
    }
}

// MARK: - MediaKind Media List Text

extension MediaKind {

    func mediaListSearchPlaceholder(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .movie:
            return localization.string("media_list.search.movie.placeholder", defaultValue: "Search Movies")

        case .tv:
            return localization.string("media_list.search.tv.placeholder", defaultValue: "Search TV Shows")
        }
    }

    func mediaListSearchAccessibilityHint(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .movie:
            return localization.string(
                "media_list.search.movie.accessibility_hint",
                defaultValue: "Enter a movie title to search"
            )

        case .tv:
            return localization.string(
                "media_list.search.tv.accessibility_hint",
                defaultValue: "Enter a TV show title to search"
            )
        }
    }

    func mediaListGenreTitle(
        genreName: String,
        localization: AppInterfaceLocalization
    ) -> String {
        switch self {
        case .movie:
            return localization.formatted(
                "media_list.genre_title.movie_format",
                defaultValue: "%@ Movies",
                genreName
            )

        case .tv:
            return localization.formatted(
                "media_list.genre_title.tv_format",
                defaultValue: "%@ TV Shows",
                genreName
            )
        }
    }

    func mediaListEmptyTitle(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .movie:
            return localization.string("media_list.empty.movie.title", defaultValue: "No Movies Available")

        case .tv:
            return localization.string("media_list.empty.tv.title", defaultValue: "No TV Shows Available")
        }
    }

    func mediaListEmptyMessage(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .movie:
            return localization.string(
                "media_list.empty.movie.message",
                defaultValue: "There are no movies to show right now."
            )

        case .tv:
            return localization.string(
                "media_list.empty.tv.message",
                defaultValue: "There are no TV shows to show right now."
            )
        }
    }

    func mediaListSortAccessibilityLabel(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .movie:
            return localization.string("media_list.sort.movie.accessibility_label", defaultValue: "Sort Movies")

        case .tv:
            return localization.string("media_list.sort.tv.accessibility_label", defaultValue: "Sort TV Shows")
        }
    }

    func mediaListSortAccessibilityHint(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .movie:
            return localization.string(
                "media_list.sort.movie.accessibility_hint",
                defaultValue: "Double-tap to choose how movies are sorted"
            )

        case .tv:
            return localization.string(
                "media_list.sort.tv.accessibility_hint",
                defaultValue: "Double-tap to choose how TV shows are sorted"
            )
        }
    }
}
