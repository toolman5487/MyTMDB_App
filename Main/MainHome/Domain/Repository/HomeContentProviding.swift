//
//  HomeContentProviding.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - HomeContentProviding

nonisolated protocol HomeContentProviding: Sendable {
    func content(
        category: HomeCategory,
        page: Int
    ) async throws -> Page<MediaSummary>
}
