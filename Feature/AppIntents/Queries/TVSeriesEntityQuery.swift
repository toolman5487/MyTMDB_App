//
//  TVSeriesEntityQuery.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import AppIntents
import Foundation

// MARK: - TVSeriesEntityQuery

nonisolated struct TVSeriesEntityQuery: EntityStringQuery {
    private let searchMedia: (any SearchMediaUseCase)?
    private let seriesDetail: (any TVDetailProviding)?

    init() {
        self.searchMedia = nil
        self.seriesDetail = nil
    }

    init(
        searchMedia: any SearchMediaUseCase,
        seriesDetail: any TVDetailProviding
    ) {
        self.searchMedia = searchMedia
        self.seriesDetail = seriesDetail
    }

    func entities(for identifiers: [TVSeriesEntity.ID]) async throws -> [TVSeriesEntity] {
        if searchMedia == nil || seriesDetail == nil {
            return try await makeComposedQuery().entities(for: identifiers)
        }

        var entities: [TVSeriesEntity] = []
        entities.reserveCapacity(identifiers.count)
        guard let seriesDetail else { return [] }

        for identifier in identifiers where identifier > 0 {
            if let detail = try? await seriesDetail.series(id: identifier) {
                entities.append(TVSeriesEntity(detail: detail))
            }
        }

        return entities
    }

    func entities(matching string: String) async throws -> [TVSeriesEntity] {
        if searchMedia == nil || seriesDetail == nil {
            return try await makeComposedQuery().entities(matching: string)
        }

        let keyword = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return [] }

        guard let searchMedia else { return [] }
        let page = try await searchMedia(kind: .tv, keyword: keyword, page: 1)
        return page.items.prefix(10).map(TVSeriesEntity.init(series:))
    }

    func suggestedEntities() async throws -> [TVSeriesEntity] {
        []
    }

    private func makeComposedQuery() async -> TVSeriesEntityQuery {
        await MainActor.run {
            AppComposition().makeTVSeriesEntityQuery()
        }
    }
}
