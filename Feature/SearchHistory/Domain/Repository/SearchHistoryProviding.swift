//
//  SearchHistoryProviding.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - SearchHistoryProviding

nonisolated protocol SearchHistoryProviding: Sendable {
    func load(scope: SearchHistoryScope?, limit: Int) -> [SearchHistoryEntry]

    func add(keyword: String, scope: SearchHistoryScope)

    func remove(id: UUID)

    func move(id: UUID, to destinationIndex: Int, scope: SearchHistoryScope)

    func clear(scope: SearchHistoryScope?)
}
