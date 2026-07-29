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

    init(
        id: UUID = UUID(),
        keyword: String,
        scope: SearchHistoryScope,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.keyword = keyword
        self.scope = scope
        self.createdAt = createdAt
    }

    static func trimmedKeyword(_ keyword: String) -> String {
        keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizedKeyword(_ keyword: String) -> String {
        trimmedKeyword(keyword).lowercased()
    }
}
