//
//  MainMemberCenterListViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import Foundation
import Observation

// MARK: - MainMemberCenterListViewModel

@MainActor
@Observable
final class MainMemberCenterListViewModel {

    // MARK: - Properties

    let destination: MainMemberCenterDestination
    private(set) var state: MainMemberCenterListViewState = .idle

    private let accountId: Int
    private let sessionId: String
    private let service: MainMemberCenterServicing

    // MARK: - Initialization

    init(
        destination: MainMemberCenterDestination,
        accountId: Int,
        sessionId: String,
        service: MainMemberCenterServicing = MainMemberCenterService()
    ) {
        self.destination = destination
        self.accountId = accountId
        self.sessionId = sessionId
        self.service = service
    }

    // MARK: - Public Methods

    func loadInitialContent() async {
        state = .loading

        do {
            let page = try await fetchPage(page: 1)
            guard !Task.isCancelled else { return }

            state = page.items.isEmpty ? .empty(destination) : .loaded(MainMemberCenterListContent(page: page))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
        }
    }

    func loadNextPageIfNeeded(currentItemID: String) async {
        guard case .loaded(let content) = state,
              content.canLoadNextPage,
              !content.isLoadingNextPage,
              shouldLoadNextPage(currentItemID: currentItemID, items: content.items) else {
            return
        }

        state = .loaded(content.updatingLoadingNextPage(true))

        do {
            let nextPage = try await fetchPage(page: content.currentPage + 1)
            guard !Task.isCancelled else { return }

            guard case .loaded(let currentContent) = state,
                  currentContent.destination == content.destination,
                  currentContent.currentPage == content.currentPage else {
                return
            }

            state = .loaded(currentContent.appending(page: nextPage))
        } catch {
            guard !Task.isCancelled else { return }

            guard case .loaded(let currentContent) = state,
                  currentContent.destination == content.destination,
                  currentContent.currentPage == content.currentPage else {
                return
            }

            state = .loaded(currentContent.updatingLoadingNextPage(false))
        }
    }

    // MARK: - Private Methods

    private func fetchPage(page: Int) async throws -> MainMemberCenterListPageResult {
        switch destination {
        case .favoriteMovies:
            let response = try await service.fetchFavoriteMovies(
                accountId: accountId,
                sessionId: sessionId,
                page: page
            )
            return makePageResult(
                response: response,
                items: response.results.map {
                    MainMemberCenterListItem(movie: $0, destination: destination)
                }
            )

        case .favoriteTV:
            let response = try await service.fetchFavoriteTV(
                accountId: accountId,
                sessionId: sessionId,
                page: page
            )
            return makePageResult(
                response: response,
                items: response.results.map {
                    MainMemberCenterListItem(series: $0, destination: destination)
                }
            )

        case .watchlistMovies:
            let response = try await service.fetchWatchlistMovies(
                accountId: accountId,
                sessionId: sessionId,
                page: page
            )
            return makePageResult(
                response: response,
                items: response.results.map {
                    MainMemberCenterListItem(movie: $0, destination: destination)
                }
            )

        case .watchlistTV:
            let response = try await service.fetchWatchlistTV(
                accountId: accountId,
                sessionId: sessionId,
                page: page
            )
            return makePageResult(
                response: response,
                items: response.results.map {
                    MainMemberCenterListItem(series: $0, destination: destination)
                }
            )

        case .ratedMovies:
            let response = try await service.fetchRatedMovies(
                accountId: accountId,
                sessionId: sessionId,
                page: page
            )
            return makePageResult(
                response: response,
                items: response.results.map {
                    MainMemberCenterListItem(movie: $0, destination: destination)
                }
            )

        case .ratedTV:
            let response = try await service.fetchRatedTV(
                accountId: accountId,
                sessionId: sessionId,
                page: page
            )
            return makePageResult(
                response: response,
                items: response.results.map {
                    MainMemberCenterListItem(series: $0, destination: destination)
                }
            )

        case .ratedEpisodes:
            let response = try await service.fetchRatedEpisodes(
                accountId: accountId,
                sessionId: sessionId,
                page: page
            )
            return makePageResult(
                response: response,
                items: response.results.map {
                    MainMemberCenterListItem(episode: $0, destination: destination)
                }
            )

        case .lists:
            let response = try await service.fetchLists(
                accountId: accountId,
                sessionId: sessionId,
                page: page
            )
            return makePageResult(
                response: response,
                items: response.results.map {
                    MainMemberCenterListItem(list: $0, destination: destination)
                }
            )
        }
    }

    private func makePageResult<Element: Decodable & Sendable>(
        response: TMDBPageResponse<Element>,
        items: [MainMemberCenterListItem]
    ) -> MainMemberCenterListPageResult {
        MainMemberCenterListPageResult(
            destination: destination,
            page: response.page,
            totalPages: response.totalPages,
            totalResults: response.totalResults,
            items: items
        )
    }

    private func shouldLoadNextPage(
        currentItemID: String,
        items: [MainMemberCenterListItem]
    ) -> Bool {
        guard let currentIndex = items.firstIndex(where: { $0.id == currentItemID }) else {
            return false
        }

        return currentIndex >= max(items.count - 4, 0)
    }
}
