//
//  MemberCenterListContentRepository.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/8/1.
//

import Foundation

// MARK: - MemberCenterListContentProviding

nonisolated protocol MemberCenterListContentProviding: Sendable {
    func fetchPage(
        for destination: MemberCenterDestination,
        accountID: Int,
        sessionID: String,
        page: Int
    ) async throws -> MemberCenterPreviewPage
}

// MARK: - MemberCenterListContentRepository

nonisolated final class MemberCenterListContentRepository: MemberCenterListContentProviding {

    // MARK: - Properties

    private let service: MemberCenterServicing
    private let listPosterEnricher: any MemberCenterListPosterEnriching

    // MARK: - Initialization

    init(
        service: MemberCenterServicing = MemberCenterService(),
        listPosterEnricher: (any MemberCenterListPosterEnriching)? = nil
    ) {
        self.service = service
        self.listPosterEnricher = listPosterEnricher ?? MemberCenterListPosterEnricher(service: service)
    }

    // MARK: - MemberCenterListContentProviding

    func fetchPage(
        for destination: MemberCenterDestination,
        accountID: Int,
        sessionID: String,
        page: Int
    ) async throws -> MemberCenterPreviewPage {
        switch destination {
        case .favoriteMovies:
            return .favoriteMovies(
                try await service.fetchFavoriteMovies(
                    accountId: accountID,
                    sessionId: sessionID,
                    page: page
                )
            )

        case .favoriteTV:
            return .favoriteTV(
                try await service.fetchFavoriteTV(
                    accountId: accountID,
                    sessionId: sessionID,
                    page: page
                )
            )

        case .watchlistMovies:
            return .watchlistMovies(
                try await service.fetchWatchlistMovies(
                    accountId: accountID,
                    sessionId: sessionID,
                    page: page
                )
            )

        case .watchlistTV:
            return .watchlistTV(
                try await service.fetchWatchlistTV(
                    accountId: accountID,
                    sessionId: sessionID,
                    page: page
                )
            )

        case .ratedMovies:
            return .ratedMovies(
                try await service.fetchRatedMovies(
                    accountId: accountID,
                    sessionId: sessionID,
                    page: page
                )
            )

        case .ratedTV:
            return .ratedTV(
                try await service.fetchRatedTV(
                    accountId: accountID,
                    sessionId: sessionID,
                    page: page
                )
            )

        case .ratedEpisodes:
            return .ratedEpisodes(
                try await service.fetchRatedEpisodes(
                    accountId: accountID,
                    sessionId: sessionID,
                    page: page
                )
            )

        case .lists:
            let response = try await service.fetchLists(
                accountId: accountID,
                sessionId: sessionID,
                page: page
            )
            let enrichedResults = try await listPosterEnricher.enrichingListsWithFirstItemPoster(
                response.results,
                limit: response.results.count
            )

            return .lists(
                MemberCenterListPage(
                    page: response.page,
                    results: enrichedResults,
                    totalPages: response.totalPages,
                    totalResults: response.totalResults
                )
            )
        }
    }
}
