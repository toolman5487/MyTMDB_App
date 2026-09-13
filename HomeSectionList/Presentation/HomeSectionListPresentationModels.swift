//
//  HomeSectionListPresentationModels.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/9.
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

// MARK: - HomeSectionListGenreItem

nonisolated struct HomeSectionListGenreItem: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let isSelected: Bool

    init(genre: MediaGenre, isSelected: Bool) {
        self.id = genre.id
        self.name = genre.name
        self.isSelected = isSelected
    }

    static func all(isSelected: Bool) -> HomeSectionListGenreItem {
        HomeSectionListGenreItem(
            genre: MediaGenre(id: HomeGenreFilterID.all, name: "全部"),
            isSelected: isSelected
        )
    }
}

// MARK: - HomeSectionListContent

nonisolated struct HomeSectionListContent: Sendable, Equatable {
    let genres: [HomeSectionListGenreItem]
    let selectedGenreID: Int
    let items: [HomeContentItem]
    let currentPage: Int
    let totalPages: Int
    let isLoadingNextPage: Bool

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }
}
