//
//  HomeSectionListViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import Foundation
import Observation

// MARK: - HomeSectionListViewModel

@MainActor
@Observable
final class HomeSectionListViewModel {

    // MARK: - Properties

    private(set) var state: HomeSectionListViewState = .idle

    private let category: MainHomeContentCategory
    private let homeService: MainHomeServicing
    private let genreService: HomeSectionListServicing
    private var genres: [HomeSectionListGenre] = []
    private var selectedGenreID = HomeSectionListGenreFilterID.all

    // MARK: - Initialization

    init(
        category: MainHomeContentCategory,
        homeService: MainHomeServicing = MainHomeService(),
        genreService: HomeSectionListServicing = HomeSectionListService()
    ) {
        self.category = category
        self.homeService = homeService
        self.genreService = genreService
    }

    // MARK: - Public Methods

    func loadInitial() async {
        state = .loading

        do {
            async let genresTask = genreService.fetchGenres(for: category.mediaType)
            async let pageTask = homeService.fetchContent(for: category, page: 1)

            let (fetchedGenres, page) = try await (genresTask, pageTask)
            guard !Task.isCancelled else { return }

            genres = [.all] + fetchedGenres
            selectedGenreID = HomeSectionListGenreFilterID.all

            let allItems = page.contents.map { content in
                MainHomeContentItem(
                    content: content,
                    mediaType: category.mediaType
                )
            }

            guard !allItems.isEmpty else {
                state = .empty
                return
            }

            state = .loaded(
                makeContent(
                    selectedGenreID: selectedGenreID,
                    allItems: allItems,
                    currentPage: page.page,
                    totalPages: page.totalPages
                )
            )
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
        }
    }

    func selectGenre(id: Int) {
        guard selectedGenreID != id else { return }
        guard genres.contains(where: { $0.id == id }) else { return }

        selectedGenreID = id

        guard case .loaded(let content) = state else { return }

        state = .loaded(content.updatingSelectedGenreID(id))
    }

    func loadNextPageIfNeeded(currentItemID: Int) async {
        guard case .loaded(let content) = state,
              content.canLoadNextPage,
              !content.isLoadingNextPage,
              shouldLoadNextPage(
                currentItemID: currentItemID,
                items: content.displayedItems
              ) else {
            return
        }

        state = .loaded(content.updatingLoadingNextPage(true))

        do {
            let nextPage = try await homeService.fetchContent(
                for: category,
                page: content.currentPage + 1
            )

            guard !Task.isCancelled else { return }

            guard case .loaded(let currentContent) = state,
                  currentContent.category == content.category,
                  currentContent.selectedGenreID == content.selectedGenreID,
                  currentContent.currentPage == content.currentPage else {
                return
            }

            state = .loaded(currentContent.appending(page: nextPage))
        } catch {
            guard !Task.isCancelled else { return }

            guard case .loaded(let currentContent) = state,
                  currentContent.category == content.category,
                  currentContent.selectedGenreID == content.selectedGenreID,
                  currentContent.currentPage == content.currentPage else {
                return
            }

            state = .loaded(currentContent.updatingLoadingNextPage(false))
        }
    }

    // MARK: - Private Methods

    private func makeContent(
        selectedGenreID: Int,
        allItems: [MainHomeContentItem],
        currentPage: Int,
        totalPages: Int
    ) -> HomeSectionListContent {
        HomeSectionListContent(
            category: category,
            genres: genres.map { genre in
                HomeSectionListGenreItem(
                    genre: genre,
                    isSelected: genre.id == selectedGenreID
                )
            },
            selectedGenreID: selectedGenreID,
            allItems: allItems,
            currentPage: currentPage,
            totalPages: totalPages,
            isLoadingNextPage: false
        )
    }

    private func shouldLoadNextPage(
        currentItemID: Int,
        items: [MainHomeContentItem]
    ) -> Bool {
        guard let currentIndex = items.firstIndex(where: { $0.id == currentItemID }) else {
            return false
        }

        return MovieGridLayoutMetrics.shouldLoadNextPage(
            currentIndex: currentIndex,
            itemCount: items.count
        )
    }
}
