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
    let posterPath: String?
    let releaseDate: CalendarDay?
    let voteAverage: Double
    let voteCount: Int
}
