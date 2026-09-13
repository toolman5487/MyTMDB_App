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
    let currentPage: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool
    let selectedSortOption: MediaSortOrder?

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }

    func updatingLoadingNextPage(_ isLoading: Bool) -> MainMediaListContent {
        MainMediaListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            items: items,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoading,
            selectedSortOption: selectedSortOption
        )
    }

    func appending(page: Page<MediaSummary>) -> MainMediaListContent {
        MainMediaListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            items: items + page.items.map(MediaGridItem.init(summary:)),
            currentPage: page.number,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false,
            selectedSortOption: selectedSortOption
        )
    }

    func updatingSortOption(_ option: MediaSortOrder) -> MainMediaListContent {
        MainMediaListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            items: items,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoadingNextPage,
            selectedSortOption: option
        )
    }
}
