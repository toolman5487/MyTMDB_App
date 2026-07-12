//
//  MainMemberCenterService.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import Foundation

// MARK: - MainMemberCenterServicing

nonisolated protocol MainMemberCenterServicing: Sendable {
    func fetchContent(sessionId: String) async throws -> MainMemberCenterContentSnapshot

    func fetchFavoriteMovies(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MainMemberCenterFavoriteMoviePage

    func fetchFavoriteTV(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MainMemberCenterFavoriteTVPage

    func fetchWatchlistMovies(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MainMemberCenterWatchlistMoviePage

    func fetchWatchlistTV(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MainMemberCenterWatchlistTVPage

    func fetchRatedMovies(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MainMemberCenterRatedMoviePage

    func fetchRatedTV(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MainMemberCenterRatedTVPage

    func fetchRatedEpisodes(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MainMemberCenterRatedEpisodePage

    func fetchLists(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MainMemberCenterListPage

    func updateFavorite(
        accountId: Int,
        sessionId: String,
        request: MainMemberCenterFavoriteStatusRequest
    ) async throws -> MainMemberCenterFavoriteStatusResponse

    func updateWatchlist(
        accountId: Int,
        sessionId: String,
        request: MainMemberCenterWatchlistStatusRequest
    ) async throws -> MainMemberCenterWatchlistStatusResponse
}

// MARK: - MainMemberCenterService

nonisolated final class MainMemberCenterService: MainMemberCenterServicing {

    // MARK: - Configuration

    private enum Configuration {
        static let listPreviewPosterFallbackLimit = 10
    }

    // MARK: - Properties

    private let network: NetworkServicing
    private let localization: AppLocalization

    // MARK: - Initialization

    init(
        network: NetworkServicing = NetworkService(),
        localization: AppLocalization = .current
    ) {
        self.network = network
        self.localization = localization
    }

    // MARK: - Public Methods

    func fetchContent(sessionId: String) async throws -> MainMemberCenterContentSnapshot {
        let account = try await fetchAccount(sessionId: sessionId)
        let profile = MainMemberCenterProfile(account: account)
        let previewPages = await fetchPreviewPages(
            accountId: profile.id,
            sessionId: sessionId
        )

        return MainMemberCenterContentSnapshot(
            profile: profile,
            previewPages: previewPages
        )
    }

    func fetchFavoriteMovies(
        accountId: Int,
        sessionId: String,
        page: Int = 1
    ) async throws -> MainMemberCenterFavoriteMoviePage {
        try await fetchAccountPage(
            path: APIConfig.Account.favoriteMovies(accountId: accountId),
            sessionId: sessionId,
            page: page
        )
    }

    func fetchFavoriteTV(
        accountId: Int,
        sessionId: String,
        page: Int = 1
    ) async throws -> MainMemberCenterFavoriteTVPage {
        try await fetchAccountPage(
            path: APIConfig.Account.favoriteTv(accountId: accountId),
            sessionId: sessionId,
            page: page
        )
    }

    func fetchWatchlistMovies(
        accountId: Int,
        sessionId: String,
        page: Int = 1
    ) async throws -> MainMemberCenterWatchlistMoviePage {
        try await fetchAccountPage(
            path: APIConfig.Account.watchlistMovies(accountId: accountId),
            sessionId: sessionId,
            page: page
        )
    }

    func fetchWatchlistTV(
        accountId: Int,
        sessionId: String,
        page: Int = 1
    ) async throws -> MainMemberCenterWatchlistTVPage {
        try await fetchAccountPage(
            path: APIConfig.Account.watchlistTv(accountId: accountId),
            sessionId: sessionId,
            page: page
        )
    }

    func fetchRatedMovies(
        accountId: Int,
        sessionId: String,
        page: Int = 1
    ) async throws -> MainMemberCenterRatedMoviePage {
        try await fetchAccountPage(
            path: APIConfig.Account.ratedMovies(accountId: accountId),
            sessionId: sessionId,
            page: page
        )
    }

    func fetchRatedTV(
        accountId: Int,
        sessionId: String,
        page: Int = 1
    ) async throws -> MainMemberCenterRatedTVPage {
        try await fetchAccountPage(
            path: APIConfig.Account.ratedTv(accountId: accountId),
            sessionId: sessionId,
            page: page
        )
    }

    func fetchRatedEpisodes(
        accountId: Int,
        sessionId: String,
        page: Int = 1
    ) async throws -> MainMemberCenterRatedEpisodePage {
        try await fetchAccountPage(
            path: APIConfig.Account.ratedTvEpisodes(accountId: accountId),
            sessionId: sessionId,
            page: page
        )
    }

    func fetchLists(
        accountId: Int,
        sessionId: String,
        page: Int = 1
    ) async throws -> MainMemberCenterListPage {
        try await fetchAccountPage(
            path: APIConfig.Account.lists(accountId: accountId),
            sessionId: sessionId,
            page: page
        )
    }

    func updateFavorite(
        accountId: Int,
        sessionId: String,
        request: MainMemberCenterFavoriteStatusRequest
    ) async throws -> MainMemberCenterFavoriteStatusResponse {
        try await network.post(
            path: APIConfig.Account.favorite(accountId: accountId),
            queryItems: authenticatedQueryItems(sessionId: sessionId),
            body: request
        )
    }

    func updateWatchlist(
        accountId: Int,
        sessionId: String,
        request: MainMemberCenterWatchlistStatusRequest
    ) async throws -> MainMemberCenterWatchlistStatusResponse {
        try await network.post(
            path: APIConfig.Account.watchlist(accountId: accountId),
            queryItems: authenticatedQueryItems(sessionId: sessionId),
            body: request
        )
    }

    // MARK: - Private Methods

    private func fetchAccount(sessionId: String) async throws -> Account {
        try await network.get(
            path: APIConfig.Account.me,
            queryItems: authenticatedQueryItems(sessionId: sessionId)
        )
    }

    private func fetchPreviewPages(
        accountId: Int,
        sessionId: String
    ) async -> [MainMemberCenterPreviewPage] {
        var previewPages: [MainMemberCenterPreviewPage] = []

        for destination in MainMemberCenterDestination.allCases {
            guard let previewPage = await fetchPreviewPage(
                destination: destination,
                accountId: accountId,
                sessionId: sessionId
            ) else {
                continue
            }

            previewPages.append(previewPage)
        }

        return previewPages
    }

    private func fetchPreviewPage(
        destination: MainMemberCenterDestination,
        accountId: Int,
        sessionId: String
    ) async -> MainMemberCenterPreviewPage? {
        do {
            switch destination {
            case .favoriteMovies:
                let page = try await fetchFavoriteMovies(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return .favoriteMovies(page)

            case .favoriteTV:
                let page = try await fetchFavoriteTV(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return .favoriteTV(page)

            case .watchlistMovies:
                let page = try await fetchWatchlistMovies(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return .watchlistMovies(page)

            case .watchlistTV:
                let page = try await fetchWatchlistTV(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return .watchlistTV(page)

            case .ratedMovies:
                let page = try await fetchRatedMovies(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return .ratedMovies(page)

            case .ratedTV:
                let page = try await fetchRatedTV(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return .ratedTV(page)

            case .ratedEpisodes:
                let page = try await fetchRatedEpisodes(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return .ratedEpisodes(page)

            case .lists:
                let page = try await fetchListsPreviewPage(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return .lists(page)
            }
        } catch {
            AppLogger.network.warning(
                "Failed to load member center preview \(destination.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return nil
        }
    }

    private func fetchAccountPage<Page: Decodable & Sendable>(
        path: String,
        sessionId: String,
        page: Int
    ) async throws -> Page {
        try await network.get(
            path: path,
            queryItems: accountListQueryItems(sessionId: sessionId, page: page)
        )
    }

    private func fetchListsPreviewPage(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MainMemberCenterListPage {
        let pageResponse = try await fetchLists(
            accountId: accountId,
            sessionId: sessionId,
            page: page
        )
        let enrichedResults = await enrichListsWithFirstItemPoster(pageResponse.results)

        return MainMemberCenterListPage(
            page: pageResponse.page,
            results: enrichedResults,
            totalPages: pageResponse.totalPages,
            totalResults: pageResponse.totalResults
        )
    }

    private func enrichListsWithFirstItemPoster(_ lists: [MainMemberCenterList]) async -> [MainMemberCenterList] {
        let network = network
        let queryItems = listDetailQueryItems()

        return await withTaskGroup(of: (Int, MainMemberCenterList).self) { group in
            for (index, list) in lists.enumerated() {
                group.addTask {
                    guard index < Configuration.listPreviewPosterFallbackLimit,
                          list.posterPath == nil else {
                        return (index, list)
                    }

                    do {
                        let detail: MainMemberCenterListDetail = try await network.get(
                            path: APIConfig.List.detail(listId: list.id),
                            queryItems: queryItems
                        )
                        return (index, list.replacingMissingPosterPath(with: detail.firstPosterPath))
                    } catch {
                        return (index, list)
                    }
                }
            }

            var indexedLists: [(Int, MainMemberCenterList)] = []
            indexedLists.reserveCapacity(lists.count)

            for await indexedList in group {
                indexedLists.append(indexedList)
            }

            return indexedLists
                .sorted { $0.0 < $1.0 }
                .map { $0.1 }
        }
    }

    private func authenticatedQueryItems(sessionId: String) -> [URLQueryItem] {
        [
            URLQueryItem(name: "session_id", value: sessionId)
        ]
    }

    private func accountListQueryItems(
        sessionId: String,
        page: Int
    ) -> [URLQueryItem] {
        [
            URLQueryItem(name: "session_id", value: sessionId),
            URLQueryItem(name: "language", value: localization.languageParameter),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ]
    }

    private func listDetailQueryItems() -> [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: localization.languageParameter),
            URLQueryItem(name: "page", value: "1")
        ]
    }
}
