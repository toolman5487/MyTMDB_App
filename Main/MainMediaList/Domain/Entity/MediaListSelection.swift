//
//  MediaListSelection.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - MediaListSelection

nonisolated struct MediaListSelection: Sendable, Equatable {
    let genres: [MediaGenre]
    let selectedGenre: MediaGenre
    let page: Page<MediaSummary>
}
