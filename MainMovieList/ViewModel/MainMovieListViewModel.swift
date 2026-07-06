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
    private var selectedSortOption: MainMovieListSortOption?

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

    func selectSortOption(_ option: MainMovieListSortOption) {
        selectedSortOption = option

        switch state {
        case .loaded(let content):
            state = .loaded(content.sorting(by: option))

        case .idle, .loading, .empty, .failed:
            break
        }
    }

    // MARK: - Private Methods

    private func makeContent(
        selectedGenre: MainMovieGenre,
        page: MainMovieListMoviePage
    ) -> MainMovieListContent {
        let movies = page.movies.map(MainMovieListMovieItem.init(movie:))

        return MainMovieListContent(
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
            movies: selectedSortOption?.sorted(movies) ?? movies,
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false,
            selectedSortOption: selectedSortOption
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
