//
//  AccountContentRepository.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import Foundation

// MARK: - AccountContentRepository

nonisolated final class AccountContentRepository: AccountContentProviding {

    // MARK: - Properties

    private let network: NetworkServicing
    private let localization: AppLocalization
    private let userProfileStore: UserProfileStoring
    private let listPosterEnricher: any AccountListPosterEnriching

    // MARK: - Initialization

    init(
        network: NetworkServicing = NetworkService(),
        localization: AppLocalization = .current,
        userProfileStore: UserProfileStoring = UserProfileStore(),
        listPosterEnricher: (any AccountListPosterEnriching)? = nil
    ) {
        self.network = network
        self.localization = localization
        self.userProfileStore = userProfileStore
        self.listPosterEnricher = listPosterEnricher
            ?? AccountListPosterEnricher(network: network, localization: localization)
    }

    // MARK: - AccountContentProviding

    func cachedProfile() -> AccountProfile? {
        userProfileStore.load()?.mapped()
    }

    func profile(sessionID: String) async throws -> AccountProfile {
        let account: Account = try await network.get(
            path: APIConfig.Account.me,
            queryItems: Self.authenticatedQueryItems(sessionID: sessionID)
        )
        userProfileStore.save(account: account)

        return account.mapped()
    }

    func collection(
        destination: MemberCenterDestination,
        accountID: Int,
        sessionID: String,
        page: Int,
        posterFallbackLimit: Int
    ) async throws -> AccountCollection {
        let path = Self.path(for: destination, accountID: accountID)
        let queryItems = collectionQueryItems(sessionID: sessionID, page: page)

        switch destination {
        case .favoriteMovies, .favoriteTV, .watchlistMovies, .watchlistTV:
            let dto: TMDBPageResponse<MediaSummaryDTO> = try await network.get(
                path: path,
                queryItems: queryItems
            )
            let kind = destination.mediaKind ?? .movie

            return AccountCollection(
                destination: destination,
                page: dto.mappedPage { .media($0.mapped(), kind: kind) }
            )

        case .ratedMovies, .ratedTV:
            let dto: TMDBPageResponse<RatedMediaDTO> = try await network.get(
                path: path,
                queryItems: queryItems
            )
            let kind = destination.mediaKind ?? .movie

            return AccountCollection(
                destination: destination,
                page: dto.mappedPage { .ratedMedia($0.mapped(kind: kind)) }
            )

        case .ratedEpisodes:
            let dto: TMDBPageResponse<RatedEpisodeDTO> = try await network.get(
                path: path,
                queryItems: queryItems
            )

            return AccountCollection(
                destination: destination,
                page: dto.mappedPage { .ratedEpisode($0.mapped()) }
            )

        case .lists:
            let dto: TMDBPageResponse<AccountListDTO> = try await network.get(
                path: path,
                queryItems: queryItems
            )
            let enrichedLists = try await listPosterEnricher.enrichingListsWithFirstItemPoster(
                dto.results.map { $0.mapped() },
                limit: posterFallbackLimit
            )

            return AccountCollection(
                destination: destination,
                page: Page(
                    number: dto.page,
                    totalPages: dto.totalPages,
                    totalResults: dto.totalResults,
                    items: enrichedLists.map(AccountCollectionItem.list)
                )
            )
        }
    }

    // MARK: - Private Methods

    private static func authenticatedQueryItems(sessionID: String) -> [URLQueryItem] {
        [
            URLQueryItem(name: "session_id", value: sessionID)
        ]
    }

    private func collectionQueryItems(sessionID: String, page: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "session_id", value: sessionID),
            URLQueryItem(name: "language", value: localization.languageParameter),
            URLQueryItem(name: "page", value: String(max(page, 1)))
        ]
    }

    private static func path(
        for destination: MemberCenterDestination,
        accountID: Int
    ) -> String {
        switch destination {
        case .favoriteMovies:
            return APIConfig.Account.favoriteMovies(accountId: accountID)

        case .favoriteTV:
            return APIConfig.Account.favoriteTv(accountId: accountID)

        case .watchlistMovies:
            return APIConfig.Account.watchlistMovies(accountId: accountID)

        case .watchlistTV:
            return APIConfig.Account.watchlistTv(accountId: accountID)

        case .ratedMovies:
            return APIConfig.Account.ratedMovies(accountId: accountID)

        case .ratedTV:
            return APIConfig.Account.ratedTv(accountId: accountID)

        case .ratedEpisodes:
            return APIConfig.Account.ratedTvEpisodes(accountId: accountID)

        case .lists:
            return APIConfig.Account.lists(accountId: accountID)
        }
    }
}

// MARK: - TMDBPageResponse Item Mapping

private extension TMDBPageResponse {

    func mappedPage(
        _ transform: (Result) -> AccountCollectionItem
    ) -> Page<AccountCollectionItem> {
        Page(
            number: page,
            totalPages: totalPages,
            totalResults: totalResults,
            items: results.map(transform)
        )
    }
}
