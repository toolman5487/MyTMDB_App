//
//  MainMemberCenterContentRepository.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import Foundation

// MARK: - MainMemberCenterContentProviding

nonisolated protocol MainMemberCenterContentProviding: Sendable {
    func cachedHeaderContent(for session: AuthSession) -> MainMemberCenterProfileHeaderContent?
    func fetchContent(sessionId: String) async throws -> MainMemberCenterContentSnapshot
}

// MARK: - MainMemberCenterContentRepository

nonisolated final class MainMemberCenterContentRepository: MainMemberCenterContentProviding {

    // MARK: - Configuration

    private enum Configuration {
        static let listPreviewPosterFallbackLimit = 10
    }

    // MARK: - Properties

    private let service: MainMemberCenterServicing
    private let userProfileStore: UserProfileStoring

    // MARK: - Initialization

    init(
        service: MainMemberCenterServicing = MainMemberCenterService(),
        userProfileStore: UserProfileStoring = UserProfileStore()
    ) {
        self.service = service
        self.userProfileStore = userProfileStore
    }

    // MARK: - Public Methods

    func cachedHeaderContent(for session: AuthSession) -> MainMemberCenterProfileHeaderContent? {
        guard case .user = session else { return nil }
        return userProfileStore.load()?.headerContent
    }

    func fetchContent(sessionId: String) async throws -> MainMemberCenterContentSnapshot {
        if let cachedSnapshot = await makeCachedContentSnapshot(sessionId: sessionId) {
            return cachedSnapshot
        }

        let account = try await service.fetchAccount(sessionId: sessionId)
        userProfileStore.save(account: account)
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

    // MARK: - Private Methods

    private func makeCachedContentSnapshot(sessionId: String) async -> MainMemberCenterContentSnapshot? {
        guard let storedProfile = userProfileStore.load(),
              let profile = MainMemberCenterProfile(storedProfile: storedProfile) else {
            return nil
        }

        let previewPages = await fetchPreviewPages(
            accountId: profile.id,
            sessionId: sessionId
        )

        return MainMemberCenterContentSnapshot(
            profile: profile,
            previewPages: previewPages
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
                let page = try await service.fetchFavoriteMovies(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return .favoriteMovies(page)

            case .favoriteTV:
                let page = try await service.fetchFavoriteTV(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return .favoriteTV(page)

            case .watchlistMovies:
                let page = try await service.fetchWatchlistMovies(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return .watchlistMovies(page)

            case .watchlistTV:
                let page = try await service.fetchWatchlistTV(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return .watchlistTV(page)

            case .ratedMovies:
                let page = try await service.fetchRatedMovies(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return .ratedMovies(page)

            case .ratedTV:
                let page = try await service.fetchRatedTV(
                    accountId: accountId,
                    sessionId: sessionId,
                    page: 1
                )
                return .ratedTV(page)

            case .ratedEpisodes:
                let page = try await service.fetchRatedEpisodes(
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

    private func fetchListsPreviewPage(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MainMemberCenterListPage {
        let pageResponse = try await service.fetchLists(
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
        await withTaskGroup(of: (Int, MainMemberCenterList).self) { group in
            for (index, list) in lists.enumerated() {
                group.addTask { [service] in
                    guard index < Configuration.listPreviewPosterFallbackLimit,
                          list.posterPath == nil else {
                        return (index, list)
                    }

                    do {
                        let detail = try await service.fetchListDetail(listId: list.id)
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
}
