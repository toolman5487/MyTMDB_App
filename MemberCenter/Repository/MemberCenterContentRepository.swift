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

// MARK: - MemberCenterListPosterEnriching

nonisolated protocol MemberCenterListPosterEnriching: Sendable {
    func enrichingListsWithFirstItemPoster(
        _ lists: [MemberCenterList],
        limit: Int
    ) async throws -> [MemberCenterList]
}

// MARK: - MemberCenterListPosterEnricher

nonisolated final class MemberCenterListPosterEnricher: MemberCenterListPosterEnriching {

    // MARK: - Properties

    private let service: MemberCenterServicing

    // MARK: - Initialization

    init(service: MemberCenterServicing) {
        self.service = service
    }

    // MARK: - Public Methods

    func enrichingListsWithFirstItemPoster(
        _ lists: [MemberCenterList],
        limit: Int
    ) async throws -> [MemberCenterList] {
        var inputs: [MemberCenterListPosterEnrichmentInput] = []
        inputs.reserveCapacity(min(max(limit, 0), lists.count))

        for (index, list) in lists.prefix(max(limit, 0)).enumerated() {
            guard list.posterPath == nil else { continue }
            inputs.append(MemberCenterListPosterEnrichmentInput(index: index, list: list))
        }

        return try await withThrowingTaskGroup(
            of: MemberCenterListPosterEnrichmentResult.self,
            returning: [MemberCenterList].self
        ) { group in
            for input in inputs {
                group.addTask(priority: .utility) { [service] in
                    do {
                        let detail = try await service.fetchListDetail(listId: input.list.id)
                        return MemberCenterListPosterEnrichmentResult(
                            index: input.index,
                            list: input.list.replacingMissingPosterPath(with: detail.firstPosterPath)
                        )
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch {
                        try Task.checkCancellation()
                        return MemberCenterListPosterEnrichmentResult(
                            index: input.index,
                            list: input.list
                        )
                    }
                }
            }

            var updatedLists = lists
            for try await enrichedList in group where updatedLists.indices.contains(enrichedList.index) {
                updatedLists[enrichedList.index] = enrichedList.list
            }
            return updatedLists
        }
    }
}

// MARK: - MemberCenterListPosterEnrichment

private nonisolated struct MemberCenterListPosterEnrichmentInput: Sendable {
    let index: Int
    let list: MemberCenterList
}

private nonisolated struct MemberCenterListPosterEnrichmentResult: Sendable {
    let index: Int
    let list: MemberCenterList
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
    private let listPosterEnricher: any MemberCenterListPosterEnriching

    // MARK: - Initialization

    init(
        service: MemberCenterServicing = MemberCenterService(),
        userProfileStore: UserProfileStoring = UserProfileStore(),
        listPosterEnricher: (any MemberCenterListPosterEnriching)? = nil
    ) {
        self.service = service
        self.userProfileStore = userProfileStore
        self.listPosterEnricher = listPosterEnricher ?? MemberCenterListPosterEnricher(service: service)
    }

    // MARK: - Public Methods

    func cachedHeaderContent(for session: AuthSession) -> MemberCenterProfileHeaderContent? {
        guard case .user = session else { return nil }
        return userProfileStore.load()?.headerContent
    }

    func fetchContent(sessionId: String) async throws -> MemberCenterContentSnapshot {
        if let cachedSnapshot = try await makeCachedContentSnapshot(sessionId: sessionId) {
            return cachedSnapshot
        }

        let account = try await service.fetchAccount(sessionId: sessionId)
        userProfileStore.save(account: account)
        let profile = MemberCenterProfile(account: account)
        let previewPages = try await fetchPreviewPages(
            accountId: profile.id,
            sessionId: sessionId
        )

        return MemberCenterContentSnapshot(
            profile: profile,
            previewPages: previewPages
        )
    }

    // MARK: - Private Methods

    private func makeCachedContentSnapshot(sessionId: String) async throws -> MemberCenterContentSnapshot? {
        guard let storedProfile = userProfileStore.load(),
              let profile = MemberCenterProfile(storedProfile: storedProfile) else {
            return nil
        }

        let previewPages = try await fetchPreviewPages(
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
    ) async throws -> [MemberCenterPreviewPage] {
        try await withThrowingTaskGroup(
            of: MemberCenterPreviewPageLoadResult.self,
            returning: [MemberCenterPreviewPage].self
        ) { group in
            for (index, destination) in MemberCenterDestination.allCases.enumerated() {
                group.addTask(priority: .userInitiated) { [self] in
                    let page = try await fetchPreviewPage(
                        destination: destination,
                        accountId: accountId,
                        sessionId: sessionId
                    )
                    return MemberCenterPreviewPageLoadResult(index: index, page: page)
                }
            }

            var completedPages: [MemberCenterPreviewPageLoadResult] = []
            completedPages.reserveCapacity(MemberCenterDestination.allCases.count)

            for try await page in group {
                completedPages.append(page)
            }

            return completedPages
                .sorted { $0.index < $1.index }
                .compactMap(\.page)
        }
    }

    private func fetchPreviewPage(
        destination: MemberCenterDestination,
        accountId: Int,
        sessionId: String
    ) async throws -> MemberCenterPreviewPage? {
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
            throw CancellationError()
        } catch {
            try Task.checkCancellation()

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
        let enrichedResults = try await listPosterEnricher.enrichingListsWithFirstItemPoster(
            pageResponse.results,
            limit: Configuration.listPreviewPosterFallbackLimit
        )

        return MemberCenterListPage(
            page: pageResponse.page,
            results: enrichedResults,
            totalPages: pageResponse.totalPages,
            totalResults: pageResponse.totalResults
        )
    }
}

// MARK: - MemberCenterPreviewPageLoadResult

private nonisolated struct MemberCenterPreviewPageLoadResult: Sendable {
    let index: Int
    let page: MemberCenterPreviewPage?
}
