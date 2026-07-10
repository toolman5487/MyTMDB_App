//
//  MainMemberCenterService.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import Foundation

// MARK: - MainMemberCenterServicing

nonisolated protocol MainMemberCenterServicing: Sendable {
    func fetchContent(sessionId: String) async throws -> MainMemberCenterContent

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

    func fetchContent(sessionId: String) async throws -> MainMemberCenterContent {
        let account = try await fetchAccount(sessionId: sessionId)
        let profile = MainMemberCenterProfile(account: account)
        let contentSections = await fetchContentSections(
            accountId: profile.id,
            sessionId: sessionId
        )

        return MainMemberCenterContent(
            profile: profile,
            contentSections: contentSections
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

    private func fetchContentSections(
        accountId: Int,
        sessionId: String
    ) async -> [MainMemberCenterSection] {
        var sections: [MainMemberCenterSection] = []

        for destination in MainMemberCenterDestination.allCases {
            guard let section = await fetchContentSection(
                destination: destination,
                accountId: accountId,
                sessionId: sessionId
            ) else {
                continue
            }

            sections.append(section)
        }

        return sections
    }

    private func fetchContentSection(
        destination: MainMemberCenterDestination,
        accountId: Int,
        sessionId: String
    ) async -> MainMemberCenterSection? {
        do {
            switch destination {
            case .favoriteMovies:
                let page = try await fetchFavoriteMovies(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return makeContentSection(
                    destination: destination,
                    items: Array(page.results.prefix(10)).map {
                        MainMemberCenterListItem(movie: $0, destination: destination)
                    }
                )

            case .favoriteTV:
                let page = try await fetchFavoriteTV(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return makeContentSection(
                    destination: destination,
                    items: Array(page.results.prefix(10)).map {
                        MainMemberCenterListItem(series: $0, destination: destination)
                    }
                )

            case .watchlistMovies:
                let page = try await fetchWatchlistMovies(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return makeContentSection(
                    destination: destination,
                    items: Array(page.results.prefix(10)).map {
                        MainMemberCenterListItem(movie: $0, destination: destination)
                    }
                )

            case .watchlistTV:
                let page = try await fetchWatchlistTV(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return makeContentSection(
                    destination: destination,
                    items: Array(page.results.prefix(10)).map {
                        MainMemberCenterListItem(series: $0, destination: destination)
                    }
                )

            case .ratedMovies:
                let page = try await fetchRatedMovies(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return makeContentSection(
                    destination: destination,
                    items: Array(page.results.prefix(10)).map {
                        MainMemberCenterListItem(movie: $0, destination: destination)
                    }
                )

            case .ratedTV:
                let page = try await fetchRatedTV(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return makeContentSection(
                    destination: destination,
                    items: Array(page.results.prefix(10)).map {
                        MainMemberCenterListItem(series: $0, destination: destination)
                    }
                )

            case .ratedEpisodes:
                let page = try await fetchRatedEpisodes(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return makeContentSection(
                    destination: destination,
                    items: Array(page.results.prefix(10)).map {
                        MainMemberCenterListItem(episode: $0, destination: destination)
                    }
                )

            case .lists:
                let page = try await fetchLists(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return makeContentSection(
                    destination: destination,
                    items: Array(page.results.prefix(10)).map {
                        MainMemberCenterListItem(list: $0, destination: destination)
                    }
                )
            }
        } catch {
            return nil
        }
    }

    private func makeContentSection(
        destination: MainMemberCenterDestination,
        items: [MainMemberCenterListItem]
    ) -> MainMemberCenterSection? {
        guard !items.isEmpty else { return nil }

        return MainMemberCenterSection(
            destination: destination,
            items: items
        )
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
}
