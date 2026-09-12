//
//  MovieCollection.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - MovieCollection

nonisolated struct MovieCollection: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let parts: [MovieCollectionPart]

    func partsExcluding(movieID: Int) -> [MovieCollectionPart] {
        parts
            .filter { $0.id != movieID }
            .sorted { lhs, rhs in
                switch (lhs.releaseDate, rhs.releaseDate) {
                case let (lhsDate?, rhsDate?):
                    return lhsDate < rhsDate

                case (.some, .none):
                    return true

                case (.none, .some), (.none, .none):
                    return false
                }
            }
    }
}

// MARK: - MovieCollectionPart

nonisolated struct MovieCollectionPart: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let releaseDate: CalendarDay?
    let voteAverage: Double
    let voteCount: Int
}
