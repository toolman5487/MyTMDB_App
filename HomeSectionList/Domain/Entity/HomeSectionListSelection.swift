//
//  HomeSectionListSelection.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - HomeGenreFilterID

nonisolated enum HomeGenreFilterID {

    /// 不套用任何類型篩選的哨兵值；TMDB 的類型 ID 不會是 0。
    static let all = 0
}

// MARK: - HomeSectionListSelection

nonisolated struct HomeSectionListSelection: Sendable, Equatable {
    let genres: [MediaGenre]
    let page: Page<MediaSummary>
}
