//
//  TVSearchModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - TVSearchResultPage

nonisolated struct TVSearchResultPage: Sendable, Equatable {
    let keyword: String
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let series: [TVGridSeries]
}

// MARK: - TVSearchContent

nonisolated struct TVSearchContent: Sendable, Equatable {
    let keyword: String
    let series: [TVGridSeriesItem]
    let currentPage: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool
    let selectedSortOption: TVSortOption?

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }

    func updatingLoadingNextPage(_ isLoading: Bool) -> TVSearchContent {
        TVSearchContent(
            keyword: keyword,
            series: series,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoading,
            selectedSortOption: selectedSortOption
        )
    }

    func appending(page: TVSearchResultPage) -> TVSearchContent {
        let nextSeries = series + page.series.map(TVGridSeriesItem.init(series:))

        return TVSearchContent(
            keyword: keyword,
            series: selectedSortOption?.sorted(nextSeries) ?? nextSeries,
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false,
            selectedSortOption: selectedSortOption
        )
    }

    func sorting(by option: TVSortOption) -> TVSearchContent {
        TVSearchContent(
            keyword: keyword,
            series: option.sorted(series),
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoadingNextPage,
            selectedSortOption: option
        )
    }
}
