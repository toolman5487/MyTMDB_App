//
//  DetailContentListPageProviding.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/24.
//

import Foundation

// MARK: - DetailContentListPageProviding

protocol DetailContentListPageProviding: Sendable {
    func loadNextPage() async throws -> DetailContentListPage
}

// MARK: - DetailContentListPage

nonisolated struct DetailContentListPage: Sendable, Equatable {
    let items: [DetailContentListItem]
    let canLoadNextPage: Bool
}
