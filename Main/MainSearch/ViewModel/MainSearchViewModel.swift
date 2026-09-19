//
//  MainSearchViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/23.
//

import Foundation

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
final class MainSearchViewModel {

    // MARK: - Properties

    private(set) var state: MainSearchViewState = .idle {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }

    private var onStateChange: (@MainActor (MainSearchViewState) -> Void)?
    private let loadDiscovery: LoadMainSearchDiscoveryUseCase
    private let repository: MainSearchProviding
    private let searchHistory: SearchHistoryProviding
    private let localization: AppInterfaceLocalization
    private let recentSearchLimit = 15
    private var cachedDailyTrendingContent: MainSearchDailyTrendingContent?

    // MARK: - Initialization

    init(
        loadDiscovery: LoadMainSearchDiscoveryUseCase,
        repository: MainSearchProviding,
        searchHistory: SearchHistoryProviding,
        localization: AppInterfaceLocalization
    ) {
        self.loadDiscovery = loadDiscovery
        self.repository = repository
        self.searchHistory = searchHistory
        self.localization = localization
    }

    // MARK: - Output Binding

    func bind(onStateChange: @escaping @MainActor (MainSearchViewState) -> Void) {
        self.onStateChange = onStateChange
        onStateChange(state)
    }

    // MARK: - Public Methods

    func loadDailyTrending() async {
        if let cachedDailyTrendingContent {
            let content = cachedDailyTrendingContent.updatingRecentSearchEntries(loadRecentSearchEntries())
            self.cachedDailyTrendingContent = content
            state = dailyTrendingState(for: content)
            return
        }

        state = .dailyTrendingLoading

        do {
            let discovery = try await loadDiscovery()
            guard !Task.isCancelled else { return }

            let page = discovery.trending
            let items = MainSearchContent.uniqueResults(
                page.items.map {
                    MainSearchResultItem(result: $0, localization: localization)
                }
            ).shuffled()
            let popularPeople = MainSearchContent.uniqueResults(
                discovery.popularPeople.map {
                    MainSearchResultItem(person: $0, localization: localization)
                }
            )

            let content = MainSearchDailyTrendingContent(
                recentSearchEntries: loadRecentSearchEntries(),
                popularPeople: popularPeople,
                items: items,
                currentPage: page.number,
                totalPages: page.totalPages,
                totalResults: page.totalResults,
                isLoadingNextPage: false
            )

            cachedDailyTrendingContent = content
            state = dailyTrendingState(for: content)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage(localization: localization))
        }
    }

    func loadNextDailyTrendingPageIfNeeded(currentItemID: String) async {
        guard case .dailyTrending(let content) = state,
              content.canLoadNextPage,
              !content.isLoadingNextPage,
              shouldLoadNextPage(currentItemID: currentItemID, results: content.items) else {
            return
        }

        state = .dailyTrending(content.updatingLoadingNextPage(true))

        do {
            let nextPage = try await repository.dailyTrending(
                page: content.currentPage + 1
            )

            guard !Task.isCancelled else { return }

            guard case .dailyTrending(let currentContent) = state,
                  currentContent.currentPage == content.currentPage else {
                return
            }

            let updatedContent = currentContent.appending(
                page: nextPage,
                localization: localization
            )
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

    func addSearchHistory(keyword: String) {
        searchHistory.add(keyword: keyword, scope: .multi)
        cachedDailyTrendingContent = cachedDailyTrendingContent?.updatingRecentSearchEntries(loadRecentSearchEntries())
    }

    func removeSearchHistory(id: UUID) {
        searchHistory.remove(id: id)
        refreshRecentSearchEntries()
    }

    func moveSearchHistory(id: UUID, to destinationIndex: Int) {
        searchHistory.move(id: id, to: destinationIndex, scope: .multi)
        refreshRecentSearchEntries()
    }

    func refreshRecentSearchEntriesIfShowingDailyTrending() {
        guard case .dailyTrending(let content) = state else { return }

        let updatedContent = content.updatingRecentSearchEntries(loadRecentSearchEntries())
        cachedDailyTrendingContent = updatedContent
        state = dailyTrendingState(for: updatedContent)
    }

    func search(keyword: String) async {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKeyword.isEmpty else {
            restoreDailyTrending()
            return
        }

        state = .searching(trimmedKeyword)

        do {
            let page = try await repository.searchResults(keyword: trimmedKeyword, page: 1)
            guard !Task.isCancelled else { return }

            let content = makeContent(keyword: trimmedKeyword, page: page)
            state = content.results.isEmpty ? .empty(trimmedKeyword) : .results(content)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage(localization: localization))
        }
    }

    func loadNextPageIfNeeded(currentItemID: String) async {
        guard case .results(let content) = state,
              content.canLoadNextPage,
              !content.isLoadingNextPage,
              shouldLoadNextPage(currentItemID: currentItemID, results: content.results) else {
            return
        }

        state = .results(content.updatingLoadingNextPage(true))

        do {
            let nextPage = try await repository.searchResults(
                keyword: content.keyword,
                page: content.currentPage + 1
            )

            guard !Task.isCancelled else { return }

            guard case .results(let currentContent) = state,
                  currentContent.keyword == content.keyword,
                  currentContent.currentPage == content.currentPage else {
                return
            }

            state = .results(currentContent.appending(
                page: nextPage,
                localization: localization
            ))
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
        page: Page<MainSearchResult>
    ) -> MainSearchContent {
        MainSearchContent(
            keyword: keyword,
            allResults: MainSearchContent.uniqueResults(page.items.map {
                MainSearchResultItem(result: $0, localization: localization)
            }),
            selectedFilter: .all,
            currentPage: page.number,
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

        let content = cachedDailyTrendingContent.updatingRecentSearchEntries(loadRecentSearchEntries())
        self.cachedDailyTrendingContent = content
        state = dailyTrendingState(for: content)
    }

    private func refreshRecentSearchEntries() {
        guard let cachedDailyTrendingContent else { return }

        let updatedContent = cachedDailyTrendingContent.updatingRecentSearchEntries(loadRecentSearchEntries())
        self.cachedDailyTrendingContent = updatedContent

        if case .dailyTrending = state {
            state = dailyTrendingState(for: updatedContent)
        }
    }

    private func loadRecentSearchEntries() -> [SearchHistoryEntry] {
        searchHistory.load(scope: .multi, limit: recentSearchLimit)
    }

    private func dailyTrendingState(for content: MainSearchDailyTrendingContent) -> MainSearchViewState {
        content.items.isEmpty && content.popularPeople.isEmpty && content.recentSearchEntries.isEmpty
            ? .dailyTrendingEmpty
            : .dailyTrending(content)
    }

    private func shouldLoadNextPage(
        currentItemID: String,
        results: [MainSearchResultItem]
    ) -> Bool {
        guard let currentIndex = results.firstIndex(where: { $0.id == currentItemID }) else {
            return false
        }

        return MediaGridLayoutMetrics.shouldLoadNextPage(
            currentIndex: currentIndex,
            itemCount: results.count
        )
    }
}
