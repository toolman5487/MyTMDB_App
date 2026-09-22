//
//  SearchPresentationModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - SearchContent

nonisolated struct SearchContent: Sendable, Equatable {
    let keyword: String
    let items: [MediaGridItem]
    private(set) var pagination: MediaGridPaginationState
    let selectedSortOption: MediaSortOrder?

    var canLoadNextPage: Bool {
        pagination.canLoadNextPage
    }

    var isLoadingNextPage: Bool {
        pagination.isLoadingNextPage
    }

    func updatingLoadingNextPage(_ isLoading: Bool) -> SearchContent {
        var content = self
        content.pagination = pagination.updatingLoadingNextPage(isLoading)
        return content
    }
}
