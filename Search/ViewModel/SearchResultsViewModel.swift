//
//  SearchResultsViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation
import Observation

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
@Observable
final class SearchResultsViewModel {

    // MARK: - Properties

    private(set) var state: SearchResultsViewState = .idle
    private(set) var selectedSortOption: MediaSortOption?

    private let mediaKind: MediaKind
    private let service: SearchServicing

    // MARK: - Initialization

    init(
        mediaKind: MediaKind,
        service: SearchServicing = SearchService()
    ) {
        self.mediaKind = mediaKind
        self.service = service
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
            let page = try await service.search(kind: mediaKind, keyword: trimmedKeyword, page: 1)
            guard !Task.isCancelled else { return }

            let content = makeSearchContent(
                keyword: page.keyword,
                items: page.entries.map(MediaGridItem.init(entry:)),
                currentPage: page.page,
                totalPages: page.totalPages,
                totalResults: page.totalResults,
                isLoadingNextPage: false
            )
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

        do {
            let nextPage = try await service.search(
                kind: mediaKind,
                keyword: content.keyword,
                page: content.currentPage + 1
            )

            guard !Task.isCancelled else { return }

            guard case .results(let currentContent) = state,
                  currentContent.keyword == content.keyword,
                  currentContent.currentPage == content.currentPage else {
                return
            }

            state = .results(currentContent.appending(page: nextPage))
        } catch {
            guard !Task.isCancelled else { return }

            guard case .results(let currentContent) = state,
                  currentContent.keyword == content.keyword,
                  currentContent.currentPage == content.currentPage else {
                return
            }

            state = .results(currentContent.updatingLoadingNextPage(false))
        }
    }

    func selectSortOption(_ option: MediaSortOption) {
        selectedSortOption = option

        guard case .results(let content) = state else { return }
        state = .results(content.sorting(by: option))
    }

    // MARK: - Private Methods

    private func makeSearchContent(
        keyword: String,
        items: [MediaGridItem],
        currentPage: Int,
        totalPages: Int,
        totalResults: Int,
        isLoadingNextPage: Bool
    ) -> SearchContent {
        SearchContent(
            keyword: keyword,
            items: selectedSortOption?.sorted(items) ?? items,
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
