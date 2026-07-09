//
//  HomeSectionListModels.swift
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

// MARK: - HomeSectionListGenreFilterID

nonisolated enum HomeSectionListGenreFilterID {
    static let all = 0
}

// MARK: - HomeSectionListGenre

nonisolated struct HomeSectionListGenre: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String

    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }

    init(movieGenre: MainMovieGenre) {
        self.id = movieGenre.id
        self.name = movieGenre.name
    }

    init(tvGenre: MainTVGenre) {
        self.id = tvGenre.id
        self.name = tvGenre.name
    }

    static var all: HomeSectionListGenre {
        HomeSectionListGenre(
            id: HomeSectionListGenreFilterID.all,
            name: "全部"
        )
    }
}

// MARK: - HomeSectionListGenreItem

nonisolated struct HomeSectionListGenreItem: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let isSelected: Bool

    init(genre: HomeSectionListGenre, isSelected: Bool) {
        self.id = genre.id
        self.name = genre.name
        self.isSelected = isSelected
    }
}

// MARK: - HomeSectionListContent

nonisolated struct HomeSectionListContent: Sendable, Equatable {
    let category: MainHomeContentCategory
    let genres: [HomeSectionListGenreItem]
    let selectedGenreID: Int
    let allItems: [MainHomeContentItem]
    let currentPage: Int
    let totalPages: Int
    let isLoadingNextPage: Bool

    init(
        category: MainHomeContentCategory,
        genres: [HomeSectionListGenreItem],
        selectedGenreID: Int,
        allItems: [MainHomeContentItem],
        currentPage: Int,
        totalPages: Int,
        isLoadingNextPage: Bool = false
    ) {
        self.category = category
        self.genres = genres
        self.selectedGenreID = selectedGenreID
        self.allItems = allItems
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.isLoadingNextPage = isLoadingNextPage
    }

    var displayedItems: [MainHomeContentItem] {
        Self.filteredItems(from: allItems, genreID: selectedGenreID)
    }

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }

    func updatingSelectedGenreID(_ genreID: Int) -> HomeSectionListContent {
        HomeSectionListContent(
            category: category,
            genres: genres.map { genre in
                HomeSectionListGenreItem(
                    genre: HomeSectionListGenre(id: genre.id, name: genre.name),
                    isSelected: genre.id == genreID
                )
            },
            selectedGenreID: genreID,
            allItems: allItems,
            currentPage: currentPage,
            totalPages: totalPages,
            isLoadingNextPage: isLoadingNextPage
        )
    }

    func updatingLoadingNextPage(_ isLoading: Bool) -> HomeSectionListContent {
        HomeSectionListContent(
            category: category,
            genres: genres,
            selectedGenreID: selectedGenreID,
            allItems: allItems,
            currentPage: currentPage,
            totalPages: totalPages,
            isLoadingNextPage: isLoading
        )
    }

    func appending(page: MainHomeContentPage) -> HomeSectionListContent {
        let nextItems = allItems + page.contents.map { content in
            MainHomeContentItem(
                content: content,
                mediaType: category.mediaType
            )
        }

        return HomeSectionListContent(
            category: category,
            genres: genres,
            selectedGenreID: selectedGenreID,
            allItems: nextItems,
            currentPage: page.page,
            totalPages: page.totalPages,
            isLoadingNextPage: false
        )
    }

    static func filteredItems(
        from items: [MainHomeContentItem],
        genreID: Int
    ) -> [MainHomeContentItem] {
        guard genreID != HomeSectionListGenreFilterID.all else {
            return items
        }

        return items.filter { $0.genreIDs.contains(genreID) }
    }
}
