//
//  AccountListPosterEnricher.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import Foundation

// MARK: - AccountListPosterEnriching

nonisolated protocol AccountListPosterEnriching: Sendable {
    func enrichingListsWithFirstItemPoster(
        _ lists: [AccountList],
        limit: Int
    ) async throws -> [AccountList]
}

// MARK: - AccountListPosterEnricher

/// TMDB 的片單清單不一定帶海報，這裡併發抓每個片單的第一個項目補上。
/// 單一片單失敗只是沒有海報，不影響其他片單。
nonisolated final class AccountListPosterEnricher: AccountListPosterEnriching {

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

    // MARK: - AccountListPosterEnriching

    func enrichingListsWithFirstItemPoster(
        _ lists: [AccountList],
        limit: Int
    ) async throws -> [AccountList] {
        var inputs: [AccountListPosterEnrichmentInput] = []
        inputs.reserveCapacity(min(max(limit, 0), lists.count))

        for (index, list) in lists.prefix(max(limit, 0)).enumerated() {
            guard list.posterPath == nil else { continue }
            inputs.append(AccountListPosterEnrichmentInput(index: index, list: list))
        }

        guard !inputs.isEmpty else { return lists }

        return try await withThrowingTaskGroup(
            of: AccountListPosterEnrichmentResult.self,
            returning: [AccountList].self
        ) { group in
            for input in inputs {
                group.addTask(priority: .utility) { [self] in
                    do {
                        let detail = try await fetchListDetail(listID: input.list.id)
                        return AccountListPosterEnrichmentResult(
                            index: input.index,
                            list: input.list.replacingMissingPosterPath(with: detail.firstPosterPath)
                        )
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch {
                        try Task.checkCancellation()
                        return AccountListPosterEnrichmentResult(
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

    // MARK: - Private Methods

    private func fetchListDetail(listID: Int) async throws -> AccountListDetailDTO {
        try await network.get(
            path: APIConfig.List.detail(listId: listID),
            queryItems: [
                URLQueryItem(name: "language", value: localization.languageParameter),
                URLQueryItem(name: "page", value: "1")
            ]
        )
    }
}

// MARK: - AccountListPosterEnrichment

private nonisolated struct AccountListPosterEnrichmentInput: Sendable {
    let index: Int
    let list: AccountList
}

private nonisolated struct AccountListPosterEnrichmentResult: Sendable {
    let index: Int
    let list: AccountList
}
