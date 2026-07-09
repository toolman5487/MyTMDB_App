//
//  MainTVListViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation
import Observation

// MARK: - MainTVListViewState

nonisolated enum MainTVListViewState: Equatable {
    case idle
    case loading
    case refreshing(MainTVListContent)
    case loaded(MainTVListContent)
    case empty
    case failed(ErrorMessage)
}

// MARK: - MainTVListViewModel

@MainActor
@Observable
final class MainTVListViewModel {

    // MARK: - Properties

    private(set) var state: MainTVListViewState = .idle

    private let service: MainTVListServicing
    private var genres: [MainTVGenre] = []
    private var selectedSortOption: TVSortOption = .popularity

    // MARK: - Initialization

    init(service: MainTVListServicing = MainTVListService()) {
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

            let page = try await service.fetchSeries(
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
            let page = try await service.fetchSeries(
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

    func loadNextPageIfNeeded(currentSeriesID: Int) async {
        guard case .loaded(let content) = state,
              content.canLoadNextPage,
              !content.isLoadingNextPage,
              shouldLoadNextPage(currentSeriesID: currentSeriesID, series: content.series) else {
            return
        }

        state = .loaded(content.updatingLoadingNextPage(true))

        do {
            let nextPage = try await service.fetchSeries(
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

    func selectSortOption(_ option: TVSortOption) async {
        guard selectedSortOption != option else { return }

        selectedSortOption = option

        switch state {
        case .loaded(let content):
            state = .refreshing(content.updatingSortOption(option))

            do {
                let page = try await service.fetchSeries(
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

    private func previewContent(for selectedGenre: MainTVGenre) -> MainTVListContent {
        MainTVListContent(
            genres: genres.map { genre in
                MainTVGenreItem(
                    genre: genre,
                    isSelected: genre.id == selectedGenre.id
                )
            },
            selectedGenre: MainTVGenreItem(
                genre: selectedGenre,
                isSelected: true
            ),
            series: [],
            currentPage: 0,
            totalPages: 0,
            totalResults: 0,
            isLoadingNextPage: false,
            selectedSortOption: selectedSortOption
        )
    }

    private func makeContent(
        selectedGenre: MainTVGenre,
        page: MainTVListSeriesPage
    ) -> MainTVListContent {
        let series = page.series.map(TVGridSeriesItem.init(series:))

        return MainTVListContent(
            genres: genres.map { genre in
                MainTVGenreItem(
                    genre: genre,
                    isSelected: genre.id == selectedGenre.id
                )
            },
            selectedGenre: MainTVGenreItem(
                genre: selectedGenre,
                isSelected: true
            ),
            series: series,
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false,
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
