//
//  MainSearchViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/23.
//

import Foundation
import Observation

// MARK: - MainSearchViewState

nonisolated enum MainSearchViewState: Equatable {
    case idle
    case dailyTrendingLoading
    case dailyTrending(MainSearchDailyTrendingContent)
    case dailyTrendingEmpty
    case typing
    case searching(String)
    case results(MainSearchContent)
    case empty(String)
    case failed(ErrorMessage)
}

// MARK: - MainSearchViewModel

@MainActor
@Observable
final class MainSearchViewModel {

    // MARK: - Properties

    private(set) var state: MainSearchViewState = .idle

    private let service: MainSearchServicing
    private var cachedDailyTrendingContent: MainSearchDailyTrendingContent?

    // MARK: - Initialization

    init(service: MainSearchServicing = MainSearchService()) {
        self.service = service
    }

    // MARK: - Public Methods

    func loadDailyTrending() async {
        if let cachedDailyTrendingContent {
            state = .dailyTrending(cachedDailyTrendingContent)
            return
        }

        state = .dailyTrendingLoading

        do {
            let page = try await service.fetchDailyTrending(page: 1)
            guard !Task.isCancelled else { return }

            let items = MainSearchContent.uniqueResults(
                page.results.map(MainSearchResultItem.init(result:))
            ).shuffled()

            let content = MainSearchDailyTrendingContent(
                items: items,
                currentPage: page.page,
                totalPages: page.totalPages,
                totalResults: page.totalResults,
                isLoadingNextPage: false
            )

            cachedDailyTrendingContent = content
            state = items.isEmpty ? .dailyTrendingEmpty : .dailyTrending(content)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
        }
    }

    func loadNextDailyTrendingPageIfNeeded(currentResultID: String) async {
        guard case .dailyTrending(let content) = state,
              content.canLoadNextPage,
              !content.isLoadingNextPage,
              shouldLoadNextPage(currentResultID: currentResultID, results: content.items) else {
            return
        }

        state = .dailyTrending(content.updatingLoadingNextPage(true))

        do {
            let nextPage = try await service.fetchDailyTrending(
                page: content.currentPage + 1
            )

            guard !Task.isCancelled else { return }

            guard case .dailyTrending(let currentContent) = state,
                  currentContent.currentPage == content.currentPage else {
                return
            }

            let updatedContent = currentContent.appending(page: nextPage)
            cachedDailyTrendingContent = updatedContent
            state = .dailyTrending(updatedContent)
        } catch {
            guard !Task.isCancelled else { return }

            guard case .dailyTrending(let currentContent) = state,
                  currentContent.currentPage == content.currentPage else {
                return
            }

            let updatedContent = currentContent.updatingLoadingNextPage(false)
            cachedDailyTrendingContent = updatedContent
            state = .dailyTrending(updatedContent)
        }
    }

    func showTypingLoading() {
        state = .typing
    }

    func showSearchLoading(keyword: String) {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        state = trimmedKeyword.isEmpty ? .idle : .searching(trimmedKeyword)
    }

    func search(keyword: String) async {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKeyword.isEmpty else {
            restoreDailyTrending()
            return
        }

        state = .searching(trimmedKeyword)

        do {
            let page = try await service.searchAll(keyword: trimmedKeyword, page: 1)
            guard !Task.isCancelled else { return }

            let content = makeContent(keyword: trimmedKeyword, page: page)
            state = content.results.isEmpty ? .empty(trimmedKeyword) : .results(content)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
        }
    }

    func loadNextPageIfNeeded(currentResultID: String) async {
        guard case .results(let content) = state,
              content.canLoadNextPage,
              !content.isLoadingNextPage,
              shouldLoadNextPage(currentResultID: currentResultID, results: content.results) else {
            return
        }

        state = .results(content.updatingLoadingNextPage(true))

        do {
            let nextPage = try await service.searchAll(
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

    func selectFilter(_ filter: MainSearchFilter) {
        guard case .results(let content) = state,
              content.selectedFilter != filter else {
            return
        }

        state = .results(content.selectingFilter(filter))
    }

    func reset() {
        restoreDailyTrending()
    }

    // MARK: - Private Methods

    private func makeContent(
        keyword: String,
        page: MainSearchResultPage
    ) -> MainSearchContent {
        MainSearchContent(
            keyword: keyword,
            allResults: MainSearchContent.uniqueResults(page.results.map(MainSearchResultItem.init(result:))),
            selectedFilter: .all,
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false
        )
    }

    private func restoreDailyTrending() {
        guard let cachedDailyTrendingContent else {
            state = .idle
            return
        }

        state = .dailyTrending(cachedDailyTrendingContent)
    }

    private func shouldLoadNextPage(
        currentResultID: String,
        results: [MainSearchResultItem]
    ) -> Bool {
        guard let currentIndex = results.firstIndex(where: { $0.id == currentResultID }) else {
            return false
        }

        return MovieGridLayoutMetrics.shouldLoadNextPage(
            currentIndex: currentIndex,
            itemCount: results.count
        )
    }
}
