//
//  PersonCredits.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - PersonCredits

nonisolated struct PersonCredits: Sendable, Equatable, Identifiable {
    let id: Int
    let cast: [PersonCreditCast]
    let crew: [PersonCreditCrew]

    static func empty(id: Int) -> PersonCredits {
        PersonCredits(id: id, cast: [], crew: [])
    }
}

// MARK: - PersonCreditMediaType

nonisolated enum PersonCreditMediaType: Sendable, Equatable {
    case movie
    case tv
    case unknown(String)
}

// MARK: - PersonCreditCast

nonisolated struct PersonCreditCast: Sendable, Equatable, Identifiable {
    let id: Int
    let adult: Bool
    let backdropPath: String?
    let character: String
    let creditID: String
    let episodeCount: Int?
    let genreIDs: [Int]
    let mediaType: PersonCreditMediaType
    let originalLanguage: String
    let originalTitle: String
    let overview: String
    let popularity: Double
    let posterPath: String?
    let primaryDate: CalendarDay?
    let title: String
    let video: Bool
    let voteAverage: Double
    let voteCount: Int
}

// MARK: - PersonCreditCrew

nonisolated struct PersonCreditCrew: Sendable, Equatable, Identifiable {
    let id: Int
    let adult: Bool
    let backdropPath: String?
    let creditID: String
    let department: String
    let episodeCount: Int?
    let genreIDs: [Int]
    let job: String
    let mediaType: PersonCreditMediaType
    let originalLanguage: String
    let originalTitle: String
    let overview: String
    let popularity: Double
    let posterPath: String?
    let primaryDate: CalendarDay?
    let title: String
    let video: Bool
    let voteAverage: Double
    let voteCount: Int
}
