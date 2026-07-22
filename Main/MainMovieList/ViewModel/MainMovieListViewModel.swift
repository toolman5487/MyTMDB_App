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
    case refreshing(MainMovieListContent)
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
    private var selectedSortOption: MovieSortOption = .popularity

    // MARK: - Initialization

    init(service: MainMovieListServicing = MainMovieListService()) {
        self.service = service
    }

    // MARK: - Public Methods

    func loadInitialContent() async {
        state = .loading

        do {
            let genres = try await service.fetchGenres()
            guard !Task.isCancelled else { return }

            guard let selectedGenre = genres.first else {
                state = .empty
                return
            }

            let page = try await service.fetchMovies(
                genreID: selectedGenre.id,
                sortOption: selectedSortOption,
                page: 1
            )
            guard !Task.isCancelled else { return }

            self.genres = genres
            state = .loaded(makeContent(selectedGenre: selectedGenre, page: page))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
        }
    }

    func selectGenre(id: Int) async {
        guard let selectedGenre = genres.first(where: { $0.id == id }) else { return }

        state = .refreshing(previewContent(for: selectedGenre))

        do {
            let page = try await service.fetchMovies(
                genreID: selectedGenre.id,
                sortOption: selectedSortOption,
                page: 1
            )
            guard !Task.isCancelled else { return }

            state = .loaded(makeContent(selectedGenre: selectedGenre, page: page))
        } catch {
            guard !Task.isCancelled else { return }
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
                sortOption: content.selectedSortOption ?? selectedSortOption,
                page: content.currentPage + 1
            )

            guard !Task.isCancelled else { return }

            guard case .loaded(let currentContent) = state,
                  currentContent.selectedGenre.id == content.selectedGenre.id,
                  currentContent.currentPage == content.currentPage,
                  currentContent.selectedSortOption == content.selectedSortOption else {
                return
            }

            state = .loaded(currentContent.appending(page: nextPage))
        } catch {
            guard !Task.isCancelled else { return }

            guard case .loaded(let currentContent) = state,
                  currentContent.selectedGenre.id == content.selectedGenre.id,
                  currentContent.currentPage == content.currentPage,
                  currentContent.selectedSortOption == content.selectedSortOption else {
                return
            }

            state = .loaded(currentContent.updatingLoadingNextPage(false))
        }
    }

    func selectSortOption(_ option: MovieSortOption) async {
        guard selectedSortOption != option else { return }

        selectedSortOption = option

        switch state {
        case .loaded(let content):
            state = .refreshing(content.updatingSortOption(option))

            do {
                let page = try await service.fetchMovies(
                    genreID: content.selectedGenre.id,
                    sortOption: option,
                    page: 1
                )

                guard !Task.isCancelled, selectedSortOption == option else { return }
                guard let selectedGenre = genres.first(where: { $0.id == content.selectedGenre.id }) else { return }

                state = .loaded(makeContent(selectedGenre: selectedGenre, page: page))
            } catch {
                guard !Task.isCancelled, selectedSortOption == option else { return }
                state = .failed(error.errorMessage)
            }

        case .idle, .loading, .refreshing, .empty, .failed:
            break
        }
    }

    // MARK: - Private Methods

    private func previewContent(for selectedGenre: MainMovieGenre) -> MainMovieListContent {
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
            movies: [],
            currentPage: 0,
            totalPages: 0,
            totalResults: 0,
            isLoadingNextPage: false,
            selectedSortOption: selectedSortOption
        )
    }

    private func makeContent(
        selectedGenre: MainMovieGenre,
        page: MainMovieListMoviePage
    ) -> MainMovieListContent {
        let movies = page.movies.map(MovieGridMovieItem.init(movie:))

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
            movies: movies,
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false,
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
