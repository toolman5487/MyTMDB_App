//
//  MainMediaListViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import Foundation

// MARK: - MainMediaListViewState

nonisolated enum MainMediaListViewState: Equatable {
    case idle
    case loading
    case refreshing(MainMediaListContent)
    case loaded(MainMediaListContent)
    case empty
    case failed(ErrorMessage)
}

// MARK: - MainMediaListViewModel

@MainActor
final class MainMediaListViewModel {

    // MARK: - Properties

    private(set) var state: MainMediaListViewState = .idle {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }

    private var onStateChange: (@MainActor (MainMediaListViewState) -> Void)?
    private let mediaKind: MediaKind
    private let service: MainMediaListServicing
    private var preferredGenreID: Int?
    private var genres: [MainMediaGenre] = []
    private var selectedSortOption: MediaSortOption = .popularity

    // MARK: - Initialization

    init(
        mediaKind: MediaKind,
        service: MainMediaListServicing = MainMediaListService(),
        initialGenreID: Int? = nil
    ) {
        self.mediaKind = mediaKind
        self.service = service
        self.preferredGenreID = initialGenreID
    }

    // MARK: - Output Binding

    func bind(onStateChange: @escaping @MainActor (MainMediaListViewState) -> Void) {
        self.onStateChange = onStateChange
        onStateChange(state)
    }

    // MARK: - Public Methods

    func loadInitialContent() async {
        state = .loading

        do {
            let genres = try await service.fetchGenres(kind: mediaKind)
            guard !Task.isCancelled else { return }

            guard let selectedGenre = initialSelectedGenre(from: genres) else {
                state = .empty
                return
            }

            let page = try await service.fetchItems(
                kind: mediaKind,
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

        preferredGenreID = selectedGenre.id
        state = .refreshing(previewContent(for: selectedGenre))

        do {
            let page = try await service.fetchItems(
                kind: mediaKind,
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
              shouldLoadNextPage(currentMovieID: currentMovieID, items: content.items) else {
            return
        }

        state = .loaded(content.updatingLoadingNextPage(true))

        do {
            let nextPage = try await service.fetchItems(
                kind: mediaKind,
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

    func selectSortOption(_ option: MediaSortOption) async {
        guard selectedSortOption != option else { return }

        selectedSortOption = option

        switch state {
        case .loaded(let content):
            state = .refreshing(content.updatingSortOption(option))

            do {
                let page = try await service.fetchItems(
                    kind: mediaKind,
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

    func loadContent(selectingGenreID genreID: Int) async {
        preferredGenreID = genreID

        guard !genres.isEmpty else {
            await loadInitialContent()
            return
        }

        await selectGenre(id: genreID)
    }

    // MARK: - Private Methods

    private func initialSelectedGenre(from genres: [MainMediaGenre]) -> MainMediaGenre? {
        if let preferredGenreID,
           let genre = genres.first(where: { $0.id == preferredGenreID }) {
            return genre
        }

        return genres.first
    }

    private func previewContent(for selectedGenre: MainMediaGenre) -> MainMediaListContent {
        MainMediaListContent(
            genres: genres.map { genre in
                MainMediaGenreItem(
                    genre: genre,
                    isSelected: genre.id == selectedGenre.id
                )
            },
            selectedGenre: MainMediaGenreItem(
                genre: selectedGenre,
                isSelected: true
            ),
            items: [],
            currentPage: 0,
            totalPages: 0,
            totalResults: 0,
            isLoadingNextPage: false,
            selectedSortOption: selectedSortOption
        )
    }

    private func makeContent(
        selectedGenre: MainMediaGenre,
        page: MainMediaListPage
    ) -> MainMediaListContent {
        let items = page.items.map(MediaGridItem.init(entry:))

        return MainMediaListContent(
            genres: genres.map { genre in
                MainMediaGenreItem(
                    genre: genre,
                    isSelected: genre.id == selectedGenre.id
                )
            },
            selectedGenre: MainMediaGenreItem(
                genre: selectedGenre,
                isSelected: true
            ),
            items: items,
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false,
            selectedSortOption: selectedSortOption
        )
    }

    private func shouldLoadNextPage(
        currentMovieID: Int,
        items: [MediaGridItem]
    ) -> Bool {
        guard let currentIndex = items.firstIndex(where: { $0.id == currentMovieID }) else {
            return false
        }

        return MediaGridLayoutMetrics.shouldLoadNextPage(
            currentIndex: currentIndex,
            itemCount: items.count
        )
    }
}
