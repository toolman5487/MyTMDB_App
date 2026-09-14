//
//  HomeSectionListSelection.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - HomeGenreFilterID

nonisolated enum HomeGenreFilterID {

    static let all = 0
}

// MARK: - HomeSectionListSelection

nonisolated struct HomeSectionListSelection: Sendable, Equatable {
    let genres: [MediaGenre]
    let page: Page<MediaSummary>
}
