//
//  MediaGenre.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - MediaGenre

nonisolated struct MediaGenre: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
}
