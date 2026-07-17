//
//  MemberCenterService.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import Foundation

// MARK: - MemberCenterServicing

nonisolated protocol MemberCenterServicing: Sendable {
    func fetchAccount(sessionId: String) async throws -> Account

    func fetchFavoriteMovies(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MemberCenterFavoriteMoviePage

    func fetchFavoriteTV(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MemberCenterFavoriteTVPage

    func fetchWatchlistMovies(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MemberCenterWatchlistMoviePage

    func fetchWatchlistTV(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MemberCenterWatchlistTVPage

    func fetchRatedMovies(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MemberCenterRatedMoviePage

    func fetchRatedTV(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MemberCenterRatedTVPage

    func fetchRatedEpisodes(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MemberCenterRatedEpisodePage

    func fetchLists(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MemberCenterListPage

    func fetchListDetail(listId: Int) async throws -> MemberCenterListDetail

    func updateFavorite(
        accountId: Int,
        sessionId: String,
        request: MemberCenterFavoriteStatusRequest
    ) async throws -> MemberCenterFavoriteStatusResponse

    func updateWatchlist(
        accountId: Int,
        sessionId: String,
        request: MemberCenterWatchlistStatusRequest
    ) async throws -> MemberCenterWatchlistStatusResponse

    func submitRating(
        sessionId: String,
        target: AccountMediaRatingTarget,
        value: Double
    ) async throws -> AccountMediaRatingResponse

    func deleteRating(
        sessionId: String,
        target: AccountMediaRatingTarget
    ) async throws -> AccountMediaRatingResponse
}

// MARK: - MemberCenterService

nonisolated final class MemberCenterService: MemberCenterServicing {

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

    func fetchFavoriteMovies(
        accountId: Int,
        sessionId: String,
        page: Int = 1
    ) async throws -> MemberCenterFavoriteMoviePage {
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
    ) async throws -> MemberCenterFavoriteTVPage {
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
    ) async throws -> MemberCenterWatchlistMoviePage {
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
    ) async throws -> MemberCenterWatchlistTVPage {
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
    ) async throws -> MemberCenterRatedMoviePage {
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
    ) async throws -> MemberCenterRatedTVPage {
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
    ) async throws -> MemberCenterRatedEpisodePage {
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
    ) async throws -> MemberCenterListPage {
        try await fetchAccountPage(
            path: APIConfig.Account.lists(accountId: accountId),
            sessionId: sessionId,
            page: page
        )
    }

    func fetchListDetail(listId: Int) async throws -> MemberCenterListDetail {
        try await network.get(
            path: APIConfig.List.detail(listId: listId),
            queryItems: listDetailQueryItems()
        )
    }

    func updateFavorite(
        accountId: Int,
        sessionId: String,
        request: MemberCenterFavoriteStatusRequest
    ) async throws -> MemberCenterFavoriteStatusResponse {
        try await network.post(
            path: APIConfig.Account.favorite(accountId: accountId),
            queryItems: authenticatedQueryItems(sessionId: sessionId),
            body: request
        )
    }

    func updateWatchlist(
        accountId: Int,
        sessionId: String,
        request: MemberCenterWatchlistStatusRequest
    ) async throws -> MemberCenterWatchlistStatusResponse {
        try await network.post(
            path: APIConfig.Account.watchlist(accountId: accountId),
            queryItems: authenticatedQueryItems(sessionId: sessionId),
            body: request
        )
    }

    func submitRating(
        sessionId: String,
        target: AccountMediaRatingTarget,
        value: Double
    ) async throws -> AccountMediaRatingResponse {
        try await network.post(
            path: ratingPath(for: target),
            queryItems: authenticatedQueryItems(sessionId: sessionId),
            body: AccountMediaRatingRequest(value: AccountMediaRatingValue.normalized(value))
        )
    }

    func deleteRating(
        sessionId: String,
        target: AccountMediaRatingTarget
    ) async throws -> AccountMediaRatingResponse {
        let emptyBody: (any Encodable)? = nil

        return try await network.delete(
            path: ratingPath(for: target),
            queryItems: authenticatedQueryItems(sessionId: sessionId),
            body: emptyBody
        )
    }

    func fetchAccount(sessionId: String) async throws -> Account {
        try await network.get(
            path: APIConfig.Account.me,
            queryItems: authenticatedQueryItems(sessionId: sessionId)
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

    private func ratingPath(for target: AccountMediaRatingTarget) -> String {
        switch target {
        case .movie(let id):
            return APIConfig.Movie.rating(id: id)

        case .tv(let seriesID):
            return APIConfig.TV.rating(seriesId: seriesID)

        case .episode(let seriesID, let seasonNumber, let episodeNumber):
            return APIConfig.TV.episodeRating(
                seriesId: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            )
        }
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
