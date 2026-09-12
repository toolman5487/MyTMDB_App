//
//  ReviewProviding.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - ReviewProviding

nonisolated protocol ReviewProviding: Sendable {
    func reviews(kind: MediaKind, mediaID: Int, page: Int) async throws -> Page<Review>
}
