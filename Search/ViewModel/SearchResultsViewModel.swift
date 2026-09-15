//
//  SearchResultsViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - SearchResultsViewState

nonisolated enum SearchResultsViewState: Equatable {
    case idle
    case typing
    case searching(String)
    case results(SearchContent)
    case empty(String)
    case failed(ErrorMessage)
}

// MARK: - SearchResultsViewModel

@MainActor
final class SearchResultsViewModel {

    // MARK: - Properties

    private(set) var state: SearchResultsViewState = .idle {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }
    private(set) var selectedSortOption: MediaSortOrder?

    private var onStateChange: (@MainActor (SearchResultsViewState) -> Void)?
    private let mediaKind: MediaKind
    private let searchMedia: SearchMediaUseCase
    private let sortMedia: SortMediaUseCase

    private var keyword = ""
    private var summaries: [MediaSummary] = []
    private var currentPage = 0
    private var totalPages = 1
    private var totalResults = 0

    // MARK: - Initialization

    init(
        mediaKind: MediaKind,
        searchMedia: SearchMediaUseCase,
        sortMedia: SortMediaUseCase
    ) {
        self.mediaKind = mediaKind
        self.searchMedia = searchMedia
        self.sortMedia = sortMedia
    }

    // MARK: - Output Binding

    func bind(onStateChange: @escaping @MainActor (SearchResultsViewState) -> Void) {
        self.onStateChange = onStateChange
        onStateChange(state)
    }

    // MARK: - Public Methods

    func showTypingLoading() {
        state = .typing
    }

    func showSearchLoading(keyword: String) {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        state = trimmedKeyword.isEmpty ? .idle : .searching(trimmedKeyword)
    }

    func reset() {
        state = .idle
    }

    func search(keyword: String) async {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKeyword.isEmpty else {
            state = .idle
            return
        }

        state = .searching(trimmedKeyword)

        do {
            let page = try await searchMedia(kind: mediaKind, keyword: trimmedKeyword, page: 1)
            guard !Task.isCancelled else { return }

            self.keyword = trimmedKeyword
            summaries = page.items
            currentPage = page.number
            totalPages = page.totalPages
            totalResults = page.totalResults

            let content = makeContent(isLoadingNextPage: false)
            state = content.items.isEmpty ? .empty(trimmedKeyword) : .results(content)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
        }
    }

    func loadNextPageIfNeeded(currentItemID: Int) async {
        guard case .results(let content) = state,
              content.canLoadNextPage,
              !content.isLoadingNextPage,
              shouldLoadNextPage(currentItemID: currentItemID, items: content.items) else {
            return
        }

        state = .results(content.updatingLoadingNextPage(true))

        let requestedKeyword = keyword
        let requestedPage = currentPage

        do {
            let nextPage = try await searchMedia(
                kind: mediaKind,
                keyword: requestedKeyword,
                page: requestedPage + 1
            )

            guard !Task.isCancelled,
                  keyword == requestedKeyword,
                  currentPage == requestedPage else {
                return
            }

            summaries += nextPage.items
            currentPage = nextPage.number
            totalPages = nextPage.totalPages
            totalResults = nextPage.totalResults
            state = .results(makeContent(isLoadingNextPage: false))
        } catch {
            guard !Task.isCancelled,
                  keyword == requestedKeyword,
                  currentPage == requestedPage else {
                return
            }

            state = .results(makeContent(isLoadingNextPage: false))
        }
    }

    func selectSortOption(_ option: MediaSortOrder) {
        selectedSortOption = option

        guard case .results = state else { return }
        state = .results(makeContent(isLoadingNextPage: false))
    }

    // MARK: - Private Methods

    private func makeContent(isLoadingNextPage: Bool) -> SearchContent {
        let ordered = selectedSortOption.map { sortMedia(summaries, order: $0) } ?? summaries

        return SearchContent(
            keyword: keyword,
            items: ordered.map(MediaGridItem.init(summary:)),
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoadingNextPage,
            selectedSortOption: selectedSortOption
        )
    }

    private func shouldLoadNextPage(
        currentItemID: Int,
        items: [MediaGridItem]
    ) -> Bool {
        guard let currentIndex = items.firstIndex(where: { $0.id == currentItemID }) else {
            return false
        }

        return MediaGridLayoutMetrics.shouldLoadNextPage(
            currentIndex: currentIndex,
            itemCount: items.count
        )
    }
}
