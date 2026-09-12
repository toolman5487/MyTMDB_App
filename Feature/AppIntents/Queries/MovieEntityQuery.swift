//
//  MovieEntityQuery.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import AppIntents
import Foundation

// MARK: - MovieEntityQuery

nonisolated struct MovieEntityQuery: EntityStringQuery {
    private let searchService: any SearchServicing
    private let lookupService: any AppIntentEntityLookupServicing

    init() {
        self.searchService = SearchService()
        self.lookupService = AppIntentEntityLookupService()
    }

    init(
        searchService: any SearchServicing,
        lookupService: any AppIntentEntityLookupServicing
    ) {
        self.searchService = searchService
        self.lookupService = lookupService
    }

    func entities(for identifiers: [MovieEntity.ID]) async throws -> [MovieEntity] {
        var entities: [MovieEntity] = []
        entities.reserveCapacity(identifiers.count)

        for identifier in identifiers where identifier > 0 {
            if let entity = try? await lookupService.fetchMovieEntity(id: identifier) {
                entities.append(entity)
            }
        }

        return entities
    }

    func entities(matching string: String) async throws -> [MovieEntity] {
        let keyword = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return [] }

        let page = try await searchService.search(kind: .movie, keyword: keyword, page: 1)
        return page.entries.prefix(10).map(MovieEntity.init(movie:))
    }

    func suggestedEntities() async throws -> [MovieEntity] {
        []
    }
}
