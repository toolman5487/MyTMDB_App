//
//  MovieSummary.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - MovieSummary

nonisolated struct MovieSummary: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let posterPath: String?
    let releaseDate: CalendarDay?
    let voteAverage: Double
    let voteCount: Int
}
