//
//  MainTVSearchResultsViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation
import Observation

// MARK: - MainTVSearchResultsViewState

nonisolated enum MainTVSearchResultsViewState: Equatable {
    case idle
    case typing
    case searching(String)
    case results(TVSearchContent)
    case empty(String)
    case failed(ErrorMessage)
}

// MARK: - MainTVSearchResultsViewModel

@MainActor
@Observable
final class MainTVSearchResultsViewModel {

    // MARK: - Properties

    private(set) var state: MainTVSearchResultsViewState = .idle
    private(set) var selectedSortOption: TVSortOption?

    private let service: TVSearchServicing

    // MARK: - Initialization

    init(service: TVSearchServicing = TVSearchService()) {
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

    func searchSeries(keyword: String) async {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKeyword.isEmpty else {
            state = .idle
            return
        }

        state = .searching(trimmedKeyword)

        do {
            let page = try await service.searchSeries(keyword: trimmedKeyword, page: 1)
            guard !Task.isCancelled else { return }

            let content = makeSearchContent(
                keyword: page.keyword,
                series: page.series.map(TVGridSeriesItem.init(series:)),
                currentPage: page.page,
                totalPages: page.totalPages,
                totalResults: page.totalResults,
                isLoadingNextPage: false
            )
            state = content.series.isEmpty ? .empty(trimmedKeyword) : .results(content)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
        }
    }

    func loadNextPageIfNeeded(currentSeriesID: Int) async {
        guard case .results(let content) = state,
              content.canLoadNextPage,
              !content.isLoadingNextPage,
              shouldLoadNextPage(currentSeriesID: currentSeriesID, series: content.series) else {
            return
        }

        state = .results(content.updatingLoadingNextPage(true))

        do {
            let nextPage = try await service.searchSeries(
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

    func selectSortOption(_ option: TVSortOption) {
        selectedSortOption = option

        guard case .results(let content) = state else { return }
        state = .results(content.sorting(by: option))
    }

    // MARK: - Private Methods

    private func makeSearchContent(
        keyword: String,
        series: [TVGridSeriesItem],
        currentPage: Int,
        totalPages: Int,
        totalResults: Int,
        isLoadingNextPage: Bool
    ) -> TVSearchContent {
        TVSearchContent(
            keyword: keyword,
            series: selectedSortOption?.sorted(series) ?? series,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoadingNextPage,
            selectedSortOption: selectedSortOption
        )
    }

    private func shouldLoadNextPage(
        currentSeriesID: Int,
        series: [TVGridSeriesItem]
    ) -> Bool {
        guard let currentIndex = series.firstIndex(where: { $0.id == currentSeriesID }) else {
            return false
        }

        return MovieGridLayoutMetrics.shouldLoadNextPage(
            currentIndex: currentIndex,
            itemCount: series.count
        )
    }
}
