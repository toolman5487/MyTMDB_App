//
//  MainMovieListViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import Foundation
import Observation

// MARK: - MainMovieListViewState

nonisolated enum MainMovieListViewState: Equatable {
    case idle
    case loading
    case loaded(MainMovieListContent)
    case searchResults(MainMovieSearchContent)
    case empty
    case failed(ErrorMessage)
}

// MARK: - MainMovieListViewModel

@MainActor
@Observable
final class MainMovieListViewModel {

    // MARK: - Properties

    private(set) var state: MainMovieListViewState = .idle

    private let service: MainMovieListServicing
    private var genres: [MainMovieGenre] = []

    // MARK: - Initialization

    init(service: MainMovieListServicing = MainMovieListService()) {
        self.service = service
    }

    // MARK: - Public Methods

    func loadInitialContent() async {
        state = .loading

        do {
            let genres = try await service.fetchGenres()
            guard let selectedGenre = genres.first else {
                state = .empty
                return
            }

            let page = try await service.fetchMovies(genreID: selectedGenre.id, page: 1)
            self.genres = genres
            state = .loaded(makeContent(selectedGenre: selectedGenre, page: page))
        } catch {
            state = .failed(error.errorMessage)
        }
    }

    func selectGenre(id: Int) async {
        guard let selectedGenre = genres.first(where: { $0.id == id }) else { return }

        do {
            let page = try await service.fetchMovies(genreID: selectedGenre.id, page: 1)
            state = .loaded(makeContent(selectedGenre: selectedGenre, page: page))
        } catch {
            state = .failed(error.errorMessage)
        }
    }

    func searchMovies(keyword: String) async {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKeyword.isEmpty else {
            await loadInitialContent()
            return
        }

        state = .loading

        do {
            let page = try await service.searchMovies(keyword: trimmedKeyword, page: 1)
            let content = makeSearchContent(page: page)
            state = content.movies.isEmpty ? .empty : .searchResults(content)
        } catch {
            state = .failed(error.errorMessage)
        }
    }

    func loadNextPageIfNeeded(currentMovieID: Int) async {
        guard case .loaded(let content) = state,
              content.canLoadNextPage,
              !content.isLoadingNextPage,
              shouldLoadNextPage(currentMovieID: currentMovieID, movies: content.movies) else {
            return
        }

        state = .loaded(content.updatingLoadingNextPage(true))

        do {
            let nextPage = try await service.fetchMovies(
                genreID: content.selectedGenre.id,
                page: content.currentPage + 1
            )

            guard case .loaded(let currentContent) = state,
                  currentContent.selectedGenre.id == content.selectedGenre.id else {
                return
            }

            state = .loaded(currentContent.appending(page: nextPage))
        } catch {
            state = .loaded(content.updatingLoadingNextPage(false))
        }
    }

    func loadNextSearchPageIfNeeded(currentMovieID: Int) async {
        guard case .searchResults(let content) = state,
              content.canLoadNextPage,
              !content.isLoadingNextPage,
              shouldLoadNextPage(currentMovieID: currentMovieID, movies: content.movies) else {
            return
        }

        state = .searchResults(content.updatingLoadingNextPage(true))

        do {
            let nextPage = try await service.searchMovies(
                keyword: content.keyword,
                page: content.currentPage + 1
            )

            guard case .searchResults(let currentContent) = state,
                  currentContent.keyword == content.keyword else {
                return
            }

            state = .searchResults(currentContent.appending(page: nextPage))
        } catch {
            state = .searchResults(content.updatingLoadingNextPage(false))
        }
    }

    // MARK: - Private Methods

    private func makeContent(
        selectedGenre: MainMovieGenre,
        page: MainMovieListMoviePage
    ) -> MainMovieListContent {
        MainMovieListContent(
            genres: genres.map { genre in
                MainMovieGenreItem(
                    genre: genre,
                    isSelected: genre.id == selectedGenre.id
                )
            },
            selectedGenre: MainMovieGenreItem(
                genre: selectedGenre,
                isSelected: true
            ),
            movies: page.movies.map(MainMovieListMovieItem.init(movie:)),
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false
        )
    }

    private func makeSearchContent(page: MainMovieSearchResultPage) -> MainMovieSearchContent {
        MainMovieSearchContent(
            keyword: page.keyword,
            movies: page.movies.map(MainMovieListMovieItem.init(movie:)),
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false
        )
    }

    private func shouldLoadNextPage(
        currentMovieID: Int,
        movies: [MainMovieListMovieItem]
    ) -> Bool {
        guard let currentIndex = movies.firstIndex(where: { $0.id == currentMovieID }) else {
            return false
        }

        return currentIndex >= max(movies.count - 4, 0)
    }
}
