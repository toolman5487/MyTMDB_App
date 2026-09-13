//
//  MediaListProviding.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - MediaListProviding

nonisolated protocol MediaListProviding: MediaGenreProviding {
    func discover(
        kind: MediaKind,
        genreID: Int,
        sortOrder: MediaSortOrder,
        page: Int
    ) async throws -> Page<MediaSummary>
}
