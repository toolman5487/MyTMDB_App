//
//  HomeSectionListModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import Foundation

// MARK: - HomeSectionListViewState

nonisolated enum HomeSectionListViewState: Equatable {
    case idle
    case loading
    case loaded(HomeSectionListContent)
    case empty
    case failed(ErrorMessage)
}

// MARK: - HomeSectionListContent

nonisolated struct HomeSectionListContent: Sendable, Equatable {
    let category: MainHomeContentCategory
    let items: [MainHomeContentItem]
    let currentPage: Int
    let totalPages: Int
    let isLoadingNextPage: Bool

    init(
        category: MainHomeContentCategory,
        items: [MainHomeContentItem],
        currentPage: Int,
        totalPages: Int,
        isLoadingNextPage: Bool = false
    ) {
        self.category = category
        self.items = items
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.isLoadingNextPage = isLoadingNextPage
    }

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }

    func updatingLoadingNextPage(_ isLoading: Bool) -> HomeSectionListContent {
        HomeSectionListContent(
            category: category,
            items: items,
            currentPage: currentPage,
            totalPages: totalPages,
            isLoadingNextPage: isLoading
        )
    }

    func appending(page: MainHomeContentPage) -> HomeSectionListContent {
        let nextItems = items + page.contents.map { content in
            MainHomeContentItem(
                content: content,
                mediaType: category.mediaType
            )
        }

        return HomeSectionListContent(
            category: category,
            items: nextItems,
            currentPage: page.page,
            totalPages: page.totalPages,
            isLoadingNextPage: false
        )
    }
}
