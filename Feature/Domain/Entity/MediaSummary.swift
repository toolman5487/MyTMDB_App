//
//  MediaSummary.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - MediaSummary

nonisolated struct MediaSummary: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: CalendarDay?
    let voteAverage: Double
    let voteCount: Int
    let popularity: Double
    let genreIDs: [Int]
}
