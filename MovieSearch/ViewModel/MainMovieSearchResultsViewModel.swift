//
//  MainMovieSearchResultsViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation
import Observation

// MARK: - MainMovieSearchResultsViewState

nonisolated enum MainMovieSearchResultsViewState: Equatable {
    case idle
    case typing
    case searching(String)
    case results(MovieSearchContent)
    case empty(String)
    case failed(ErrorMessage)
}

// MARK: - MainMovieSearchResultsViewModel

@MainActor
@Observable
final class MainMovieSearchResultsViewModel {

    // MARK: - Properties

    private(set) var state: MainMovieSearchResultsViewState = .idle
    private(set) var selectedSortOption: MovieSortOption?

    private let service: MovieSearchServicing

    // MARK: - Initialization

    init(service: MovieSearchServicing = MovieSearchService()) {
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

    func searchMovies(keyword: String) async {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKeyword.isEmpty else {
            state = .idle
            return
        }

        state = .searching(trimmedKeyword)

        do {
            let page = try await service.searchMovies(keyword: trimmedKeyword, page: 1)
            guard !Task.isCancelled else { return }

            let content = makeSearchContent(
                keyword: page.keyword,
                movies: page.movies.map(MovieGridMovieItem.init(movie:)),
                currentPage: page.page,
                totalPages: page.totalPages,
                totalResults: page.totalResults,
                isLoadingNextPage: false
            )
            state = content.movies.isEmpty ? .empty(trimmedKeyword) : .results(content)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
        }
    }

    func loadNextPageIfNeeded(currentMovieID: Int) async {
        guard case .results(let content) = state,
              content.canLoadNextPage,
              !content.isLoadingNextPage,
              shouldLoadNextPage(currentMovieID: currentMovieID, movies: content.movies) else {
            return
        }

        state = .results(content.updatingLoadingNextPage(true))

        do {
            let nextPage = try await service.searchMovies(
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

    func selectSortOption(_ option: MovieSortOption) {
        selectedSortOption = option

        guard case .results(let content) = state else { return }
        state = .results(content.sorting(by: option))
    }

    // MARK: - Private Methods

    private func makeSearchContent(
        keyword: String,
        movies: [MovieGridMovieItem],
        currentPage: Int,
        totalPages: Int,
        totalResults: Int,
        isLoadingNextPage: Bool
    ) -> MovieSearchContent {
        MovieSearchContent(
            keyword: keyword,
            movies: selectedSortOption?.sorted(movies) ?? movies,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoadingNextPage,
            selectedSortOption: selectedSortOption
        )
    }

    private func shouldLoadNextPage(
        currentMovieID: Int,
        movies: [MovieGridMovieItem]
    ) -> Bool {
        guard let currentIndex = movies.firstIndex(where: { $0.id == currentMovieID }) else {
            return false
        }

        return MovieGridLayoutMetrics.shouldLoadNextPage(
            currentIndex: currentIndex,
            itemCount: movies.count
        )
    }
}
