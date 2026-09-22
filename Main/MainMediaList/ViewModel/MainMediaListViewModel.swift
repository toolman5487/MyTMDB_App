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
    private let loadMediaList: LoadMediaListUseCase
    private let repository: MediaListProviding
    private let localization: AppInterfaceLocalization
    private var preferredGenreID: Int?
    private var genres: [MediaGenre] = []
    private var selectedSortOption: MediaSortOrder = .popularity

    // MARK: - Initialization

    init(
        mediaKind: MediaKind,
        loadMediaList: LoadMediaListUseCase,
        repository: MediaListProviding,
        initialGenreID: Int? = nil,
        localization: AppInterfaceLocalization
    ) {
        self.mediaKind = mediaKind
        self.loadMediaList = loadMediaList
        self.repository = repository
        self.preferredGenreID = initialGenreID
        self.localization = localization
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
            let selection = try await loadMediaList(
                kind: mediaKind,
                preferredGenreID: preferredGenreID,
                sortOrder: selectedSortOption
            )
            guard !Task.isCancelled else { return }

            guard let selection else {
                state = .empty
                return
            }

            genres = selection.genres
            state = .loaded(MainMediaListPresentationBuilder.makeContent(
                genres: genres,
                selectedGenre: selection.selectedGenre,
                page: selection.page,
                selectedSortOption: selectedSortOption,
                localization: localization
            ))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage(localization: localization))
        }
    }

    func selectGenre(id: Int) async {
        guard let selectedGenre = genres.first(where: { $0.id == id }) else { return }

        preferredGenreID = selectedGenre.id
        state = .refreshing(MainMediaListPresentationBuilder.makePreviewContent(
            genres: genres,
            selectedGenre: selectedGenre,
            selectedSortOption: selectedSortOption
        ))

        do {
            let page = try await repository.discover(
                kind: mediaKind,
                genreID: selectedGenre.id,
                sortOrder: selectedSortOption,
                page: 1
            )
            guard !Task.isCancelled else { return }

            state = .loaded(MainMediaListPresentationBuilder.makeContent(
                genres: genres,
                selectedGenre: selectedGenre,
                page: page,
                selectedSortOption: selectedSortOption,
                localization: localization
            ))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage(localization: localization))
        }
    }

    func loadNextPageIfNeeded(currentItemID: Int) async {
        guard case .loaded(let content) = state,
              content.pagination.shouldLoadNextPage(currentItemID: currentItemID, items: content.items) else {
            return
        }

        state = .loaded(content.updatingLoadingNextPage(true))

        do {
            let nextPage = try await repository.discover(
                kind: mediaKind,
                genreID: content.selectedGenre.id,
                sortOrder: content.selectedSortOption ?? selectedSortOption,
                page: content.pagination.nextPage
            )

            guard !Task.isCancelled else { return }

            guard case .loaded(let currentContent) = state,
                  currentContent.selectedGenre.id == content.selectedGenre.id,
                  currentContent.pagination.currentPage == content.pagination.currentPage,
                  currentContent.selectedSortOption == content.selectedSortOption else {
                return
            }

            state = .loaded(currentContent.appending(
                page: nextPage,
                localization: localization
            ))
        } catch {
            guard !Task.isCancelled else { return }

            guard case .loaded(let currentContent) = state,
                  currentContent.selectedGenre.id == content.selectedGenre.id,
                  currentContent.pagination.currentPage == content.pagination.currentPage,
                  currentContent.selectedSortOption == content.selectedSortOption else {
                return
            }

            state = .loaded(currentContent.updatingLoadingNextPage(false))
        }
    }

    func selectSortOption(_ option: MediaSortOrder) async {
        guard selectedSortOption != option else { return }

        selectedSortOption = option

        switch state {
        case .loaded(let content):
            state = .refreshing(content.updatingSortOption(option))

            do {
                let page = try await repository.discover(
                    kind: mediaKind,
                    genreID: content.selectedGenre.id,
                    sortOrder: option,
                    page: 1
                )

                guard !Task.isCancelled, selectedSortOption == option else { return }
                guard let selectedGenre = genres.first(where: { $0.id == content.selectedGenre.id }) else { return }

                state = .loaded(MainMediaListPresentationBuilder.makeContent(
                    genres: genres,
                    selectedGenre: selectedGenre,
                    page: page,
                    selectedSortOption: selectedSortOption,
                    localization: localization
                ))
            } catch {
                guard !Task.isCancelled, selectedSortOption == option else { return }
                state = .failed(error.errorMessage(localization: localization))
            }

        case .idle, .loading, .refreshing, .empty, .failed:
            break
        }
    }

    func loadInitialContent(selectingGenreID genreID: Int) async {
        preferredGenreID = genreID

        guard !genres.isEmpty else {
            await loadInitialContent()
            return
        }

        await selectGenre(id: genreID)
    }
}
