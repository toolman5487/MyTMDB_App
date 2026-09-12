//
//  MainMediaListModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import Foundation

// MARK: - MainMediaGenreResponse

nonisolated struct MainMediaGenreResponse: Decodable, Sendable, Equatable {
    let genres: [MainMediaGenre]
}

// MARK: - MainMediaGenre

nonisolated struct MainMediaGenre: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - MainMediaListPage

nonisolated struct MainMediaListPage: Sendable, Equatable {
    let genreID: Int
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let items: [MediaGridEntry]
}

// MARK: - MainMediaGenreItem

nonisolated struct MainMediaGenreItem: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let isSelected: Bool

    init(
        genre: MainMediaGenre,
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
    let selectedSortOption: MediaSortOption?

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

    func appending(page: MainMediaListPage) -> MainMediaListContent {
        let nextMovies = items + page.items.map(MediaGridItem.init(entry:))

        return MainMediaListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            items: nextMovies,
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false,
            selectedSortOption: selectedSortOption
        )
    }

    func updatingSortOption(_ option: MediaSortOption) -> MainMediaListContent {
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
