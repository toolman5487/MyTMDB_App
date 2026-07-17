//
//  MemberCenterContentRepository.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import Foundation

// MARK: - MemberCenterContentProviding

nonisolated protocol MemberCenterContentProviding: Sendable {
    func cachedHeaderContent(for session: AuthSession) -> MemberCenterProfileHeaderContent?
    func fetchContent(sessionId: String) async throws -> MemberCenterContentSnapshot
}

// MARK: - MemberCenterContentRepository

nonisolated final class MemberCenterContentRepository: MemberCenterContentProviding {

    // MARK: - Configuration

    private enum Configuration {
        static let listPreviewPosterFallbackLimit = 10
    }

    // MARK: - Properties

    private let service: MemberCenterServicing
    private let userProfileStore: UserProfileStoring

    // MARK: - Initialization

    init(
        service: MemberCenterServicing = MemberCenterService(),
        userProfileStore: UserProfileStoring = UserProfileStore()
    ) {
        self.service = service
        self.userProfileStore = userProfileStore
    }

    // MARK: - Public Methods

    func cachedHeaderContent(for session: AuthSession) -> MemberCenterProfileHeaderContent? {
        guard case .user = session else { return nil }
        return userProfileStore.load()?.headerContent
    }

    func fetchContent(sessionId: String) async throws -> MemberCenterContentSnapshot {
        if let cachedSnapshot = await makeCachedContentSnapshot(sessionId: sessionId) {
            return cachedSnapshot
        }

        let account = try await service.fetchAccount(sessionId: sessionId)
        userProfileStore.save(account: account)
        let profile = MemberCenterProfile(account: account)
        let previewPages = await fetchPreviewPages(
            accountId: profile.id,
            sessionId: sessionId
        )

        return MemberCenterContentSnapshot(
            profile: profile,
            previewPages: previewPages
        )
    }

    // MARK: - Private Methods

    private func makeCachedContentSnapshot(sessionId: String) async -> MemberCenterContentSnapshot? {
        guard let storedProfile = userProfileStore.load(),
              let profile = MemberCenterProfile(storedProfile: storedProfile) else {
            return nil
        }

        let previewPages = await fetchPreviewPages(
            accountId: profile.id,
            sessionId: sessionId
        )

        return MemberCenterContentSnapshot(
            profile: profile,
            previewPages: previewPages
        )
    }

    private func fetchPreviewPages(
        accountId: Int,
        sessionId: String
    ) async -> [MemberCenterPreviewPage] {
        var previewPages: [MemberCenterPreviewPage] = []

        for destination in MemberCenterDestination.allCases {
            guard !Task.isCancelled else { break }

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
        destination: MemberCenterDestination,
        accountId: Int,
        sessionId: String
    ) async -> MemberCenterPreviewPage? {
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
        } catch is CancellationError {
            return nil
        } catch {
            guard !Task.isCancelled else { return nil }

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
    ) async throws -> MemberCenterListPage {
        let pageResponse = try await service.fetchLists(
            accountId: accountId,
            sessionId: sessionId,
            page: page
        )
        let enrichedResults = await enrichListsWithFirstItemPoster(pageResponse.results)

        return MemberCenterListPage(
            page: pageResponse.page,
            results: enrichedResults,
            totalPages: pageResponse.totalPages,
            totalResults: pageResponse.totalResults
        )
    }

    private func enrichListsWithFirstItemPoster(_ lists: [MemberCenterList]) async -> [MemberCenterList] {
        await withTaskGroup(of: (Int, MemberCenterList).self) { group in
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

            var indexedLists: [(Int, MemberCenterList)] = []
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
