//
//  SearchHistoryModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/29.
//

import Foundation

// MARK: - SearchHistoryScope

nonisolated enum SearchHistoryScope: String, CaseIterable, Codable, Sendable, Equatable {
    case multi
    case movie
    case tv
}

// MARK: - SearchHistoryEntry

nonisolated struct SearchHistoryEntry: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let keyword: String
    let scope: SearchHistoryScope
    let createdAt: Date
    let sortIndex: Int

    private enum CodingKeys: String, CodingKey {
        case id
        case keyword
        case scope
        case createdAt
        case sortIndex
    }

    init(
        id: UUID = UUID(),
        keyword: String,
        scope: SearchHistoryScope,
        createdAt: Date = Date(),
        sortIndex: Int = Int.max
    ) {
        self.id = id
        self.keyword = keyword
        self.scope = scope
        self.createdAt = createdAt
        self.sortIndex = sortIndex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        keyword = try container.decode(String.self, forKey: .keyword)
        scope = try container.decode(SearchHistoryScope.self, forKey: .scope)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        sortIndex = try container.decodeIfPresent(Int.self, forKey: .sortIndex) ?? Int.max
    }

    static func trimmedKeyword(_ keyword: String) -> String {
        keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizedKeyword(_ keyword: String) -> String {
        trimmedKeyword(keyword).lowercased()
    }

    func updating(keyword: String, createdAt: Date) -> SearchHistoryEntry {
        SearchHistoryEntry(
            id: id,
            keyword: keyword,
            scope: scope,
            createdAt: createdAt,
            sortIndex: sortIndex
        )
    }

    func updatingSortIndex(_ sortIndex: Int) -> SearchHistoryEntry {
        SearchHistoryEntry(
            id: id,
            keyword: keyword,
            scope: scope,
            createdAt: createdAt,
            sortIndex: sortIndex
        )
    }
}
