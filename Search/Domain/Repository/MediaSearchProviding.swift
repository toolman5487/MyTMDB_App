//
//  MediaSearchProviding.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - MediaSearchProviding

nonisolated protocol MediaSearchProviding: Sendable {
    func search(kind: MediaKind, keyword: String, page: Int) async throws -> Page<MediaSummary>
}
