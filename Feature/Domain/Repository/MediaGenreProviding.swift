//
//  MediaGenreProviding.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - MediaGenreProviding

nonisolated protocol MediaGenreProviding: Sendable {
    func genres(kind: MediaKind) async throws -> [MediaGenre]
}
