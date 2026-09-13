//
//  LoadMemberCenterOverviewUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - LoadMemberCenterOverviewUseCase

nonisolated protocol LoadMemberCenterOverviewUseCase: Sendable {
    func callAsFunction(sessionID: String) async throws -> MemberCenterOverview
}

// MARK: - DefaultLoadMemberCenterOverviewUseCase

nonisolated struct DefaultLoadMemberCenterOverviewUseCase: LoadMemberCenterOverviewUseCase {

    private enum Configuration {
        /// 首頁預覽只替前 10 筆片單補海報，避免一次打太多 list detail。
        static let listPosterFallbackLimit = 10
    }

    // MARK: - Properties

    private let repository: AccountContentProviding

    // MARK: - Initialization

    init(repository: AccountContentProviding) {
        self.repository = repository
    }

    // MARK: - LoadMemberCenterOverviewUseCase

    /// 先取得帳號（優先用本機快取省一次往返），再併發載入八種蒐藏。
    /// 單一蒐藏失敗只會讓該區塊消失，不影響其他區塊。
    func callAsFunction(sessionID: String) async throws -> MemberCenterOverview {
        let profile = try await resolveProfile(sessionID: sessionID)
        let collections = try await loadCollections(
            accountID: profile.id,
            sessionID: sessionID
        )

        return MemberCenterOverview(profile: profile, collections: collections)
    }

    // MARK: - Private Methods

    private func resolveProfile(sessionID: String) async throws -> AccountProfile {
        if let cachedProfile = repository.cachedProfile() {
            return cachedProfile
        }

        return try await repository.profile(sessionID: sessionID)
    }

    private func loadCollections(
        accountID: Int,
        sessionID: String
    ) async throws -> [AccountCollection] {
        let repository = self.repository

        let results = try await withThrowingTaskGroup(
            of: AccountCollectionLoadResult.self,
            returning: [AccountCollectionLoadResult].self
        ) { group in
            for (index, destination) in MemberCenterDestination.allCases.enumerated() {
                group.addTask(priority: .userInitiated) {
                    do {
                        let collection = try await repository.collection(
                            destination: destination,
                            accountID: accountID,
                            sessionID: sessionID,
                            page: 1,
                            posterFallbackLimit: Configuration.listPosterFallbackLimit
                        )
                        return AccountCollectionLoadResult(index: index, collection: collection)
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch {
                        try Task.checkCancellation()

                        AppLogger.network.warning(
                            "Failed to load member center preview \(destination.rawValue, privacy: .public): \(String(describing: error), privacy: .public)"
                        )
                        return AccountCollectionLoadResult(index: index, collection: nil)
                    }
                }
            }

            var completedResults: [AccountCollectionLoadResult] = []
            completedResults.reserveCapacity(MemberCenterDestination.allCases.count)

            for try await result in group {
                completedResults.append(result)
            }

            return completedResults
        }

        return results
            .sorted { $0.index < $1.index }
            .compactMap(\.collection)
    }
}

// MARK: - AccountCollectionLoadResult

private nonisolated struct AccountCollectionLoadResult: Sendable {
    let index: Int
    let collection: AccountCollection?
}
