//
//  MainTVListModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - MainTVGenreResponse

nonisolated struct MainTVGenreResponse: Decodable, Sendable, Equatable {
    let genres: [MainTVGenre]
}

// MARK: - MainTVGenre

nonisolated struct MainTVGenre: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - MainTVListSeriesPage

nonisolated struct MainTVListSeriesPage: Sendable, Equatable {
    let genreID: Int
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let series: [MediaGridEntry]
}

// MARK: - MainTVGenreItem

nonisolated struct MainTVGenreItem: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let isSelected: Bool

    init(
        genre: MainTVGenre,
        isSelected: Bool
    ) {
        self.id = genre.id
        self.name = BaseFormatter.SimplifiedChineseTextMapper.traditionalChinese(from: genre.name)
        self.isSelected = isSelected
    }
}

// MARK: - MainTVListContent

nonisolated struct MainTVListContent: Sendable, Equatable {
    let genres: [MainTVGenreItem]
    let selectedGenre: MainTVGenreItem
    let series: [MediaGridItem]
    let currentPage: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool
    let selectedSortOption: MediaSortOption?

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }

    func updatingLoadingNextPage(_ isLoading: Bool) -> MainTVListContent {
        MainTVListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            series: series,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoading,
            selectedSortOption: selectedSortOption
        )
    }

    func appending(page: MainTVListSeriesPage) -> MainTVListContent {
        let nextSeries = series + page.series.map(MediaGridItem.init(entry:))

        return MainTVListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            series: nextSeries,
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false,
            selectedSortOption: selectedSortOption
        )
    }

    func updatingSortOption(_ option: MediaSortOption) -> MainTVListContent {
        MainTVListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            series: series,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoadingNextPage,
            selectedSortOption: option
        )
    }
}
