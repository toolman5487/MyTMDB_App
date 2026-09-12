//
//  SearchModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - SearchResultPage

nonisolated struct SearchResultPage: Sendable, Equatable {
    let keyword: String
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let entries: [MediaGridEntry]
}

// MARK: - SearchContent

nonisolated struct SearchContent: Sendable, Equatable {
    let keyword: String
    let items: [MediaGridItem]
    let currentPage: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool
    let selectedSortOption: MediaSortOption?

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }

    func updatingLoadingNextPage(_ isLoading: Bool) -> SearchContent {
        SearchContent(
            keyword: keyword,
            items: items,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoading,
            selectedSortOption: selectedSortOption
        )
    }

    func appending(page: SearchResultPage) -> SearchContent {
        let nextItems = items + page.entries.map(MediaGridItem.init(entry:))

        return SearchContent(
            keyword: keyword,
            items: selectedSortOption?.sorted(nextItems) ?? nextItems,
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false,
            selectedSortOption: selectedSortOption
        )
    }

    func sorting(by option: MediaSortOption) -> SearchContent {
        SearchContent(
            keyword: keyword,
            items: option.sorted(items),
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoadingNextPage,
            selectedSortOption: option
        )
    }
}
