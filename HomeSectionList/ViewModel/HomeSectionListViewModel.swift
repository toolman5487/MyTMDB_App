//
//  HomeSectionListViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import Foundation

// MARK: - HomeSectionListViewModel

@MainActor
final class HomeSectionListViewModel {

    // MARK: - Properties

    private(set) var state: HomeSectionListViewState = .idle {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }

    private var onStateChange: (@MainActor (HomeSectionListViewState) -> Void)?

    private let category: HomeCategory
    private let loadSectionList: LoadHomeSectionListUseCase
    private let filterByGenre: FilterMediaByGenreUseCase
    private let contentRepository: HomeContentProviding
    private let localization: AppInterfaceLocalization

    private var genres: [MediaGenre] = []
    private var summaries: [MediaSummary] = []
    private var selectedGenreID = HomeGenreFilterID.all
    private var pagination = MediaGridPaginationState(currentPage: 1, totalPages: 1, totalResults: 0)

    // MARK: - Initialization

    init(
        category: HomeCategory,
        loadSectionList: LoadHomeSectionListUseCase,
        filterByGenre: FilterMediaByGenreUseCase,
        contentRepository: HomeContentProviding,
        localization: AppInterfaceLocalization
    ) {
        self.category = category
        self.contentRepository = contentRepository
        self.filterByGenre = filterByGenre
        self.loadSectionList = loadSectionList
        self.localization = localization
    }

    // MARK: - Output Binding

    func bind(onStateChange: @escaping @MainActor (HomeSectionListViewState) -> Void) {
        self.onStateChange = onStateChange
        onStateChange(state)
    }

    // MARK: - Public Methods

    func loadInitialContent() async {
        state = .loading

        do {
            let selection = try await loadSectionList(category: category)
            guard !Task.isCancelled else { return }

            genres = selection.genres
            selectedGenreID = HomeGenreFilterID.all
            summaries = selection.page.items
            pagination = MediaGridPaginationState(page: selection.page)

            guard !summaries.isEmpty else {
                state = .empty
                return
            }

            state = .loaded(makeContent(isLoadingNextPage: false))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage(localization: localization))
        }
    }

    func selectGenre(id: Int) {
        guard selectedGenreID != id else { return }
        guard id == HomeGenreFilterID.all || genres.contains(where: { $0.id == id }) else { return }

        selectedGenreID = id

        guard case .loaded = state else { return }

        state = .loaded(makeContent(isLoadingNextPage: false))
    }

    func loadNextPageIfNeeded(currentItemID: Int) async {
        guard case .loaded(let content) = state,
              content.pagination.shouldLoadNextPage(currentItemID: currentItemID, items: content.items) else {
            return
        }

        let requestedGenreID = selectedGenreID
        let requestedPage = pagination.currentPage

        state = .loaded(makeContent(isLoadingNextPage: true))

        do {
            let nextPage = try await contentRepository.content(
                category: category,
                page: requestedPage + 1
            )

            guard !Task.isCancelled,
                  isCurrentRequest(genreID: requestedGenreID, page: requestedPage) else {
                return
            }

            summaries += nextPage.items
            pagination = MediaGridPaginationState(page: nextPage)

            state = .loaded(makeContent(isLoadingNextPage: false))
        } catch {
            guard !Task.isCancelled,
                  isCurrentRequest(genreID: requestedGenreID, page: requestedPage) else {
                return
            }

            state = .loaded(makeContent(isLoadingNextPage: false))
        }
    }

    // MARK: - Private Methods

    private var displayedSummaries: [MediaSummary] {
        filterByGenre(summaries, genreID: selectedGenreID)
    }

    private func isCurrentRequest(genreID: Int, page: Int) -> Bool {
        guard case .loaded = state else { return false }
        return selectedGenreID == genreID && pagination.currentPage == page
    }

    private func makeContent(isLoadingNextPage: Bool) -> HomeSectionListContent {
        let genreItems = [HomeSectionListGenreItem.all(
            isSelected: selectedGenreID == HomeGenreFilterID.all,
            localization: localization
        )] + genres.map { genre in
            HomeSectionListGenreItem(
                genre: genre,
                isSelected: genre.id == selectedGenreID
            )
        }

        return HomeSectionListContent(
            genres: genreItems,
            selectedGenreID: selectedGenreID,
            items: displayedSummaries.map { summary in
                HomeContentItem(
                    summary: summary,
                    mediaType: category.mediaType,
                    localization: localization
                )
            },
            pagination: pagination.updatingLoadingNextPage(isLoadingNextPage)
        )
    }
}
