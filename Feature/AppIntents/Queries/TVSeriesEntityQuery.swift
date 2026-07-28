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
    private let searchService: any TVSearchServicing
    private let lookupService: any AppIntentEntityLookupServicing

    init() {
        self.searchService = TVSearchService()
        self.lookupService = AppIntentEntityLookupService()
    }

    init(
        searchService: any TVSearchServicing,
        lookupService: any AppIntentEntityLookupServicing
    ) {
        self.searchService = searchService
        self.lookupService = lookupService
    }

    func entities(for identifiers: [TVSeriesEntity.ID]) async throws -> [TVSeriesEntity] {
        var entities: [TVSeriesEntity] = []
        entities.reserveCapacity(identifiers.count)

        for identifier in identifiers where identifier > 0 {
            if let entity = try? await lookupService.fetchTVSeriesEntity(id: identifier) {
                entities.append(entity)
            }
        }

        return entities
    }

    func entities(matching string: String) async throws -> [TVSeriesEntity] {
        let keyword = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return [] }

        let page = try await searchService.searchSeries(keyword: keyword, page: 1)
        return page.series.prefix(10).map(TVSeriesEntity.init(series:))
    }

    func suggestedEntities() async throws -> [TVSeriesEntity] {
        []
    }
}
