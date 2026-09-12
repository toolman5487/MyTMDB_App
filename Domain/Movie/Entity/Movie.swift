//
//  Movie.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - Movie

nonisolated struct Movie: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let originalTitle: String
    let tagline: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let genres: [Genre]
    let productionCompanies: [ProductionCompany]
    let releaseDate: CalendarDay?
    let runtime: Duration?
    let budget: Int
    let revenue: Int
    let voteAverage: Double
    let voteCount: Int
    let status: MovieStatus
    let homepage: URL?
    let imdbID: String?
    let collectionID: Int?
}

// MARK: - Genre

nonisolated struct Genre: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - ProductionCompany

nonisolated struct ProductionCompany: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let logoPath: String?
    let originCountry: String
}

// MARK: - MovieStatus

nonisolated enum MovieStatus: Sendable, Equatable {
    case rumored
    case planned
    case inProduction
    case postProduction
    case released
    case canceled
    case other(String)

    var rawText: String {
        switch self {
        case .rumored:
            return "Rumored"

        case .planned:
            return "Planned"

        case .inProduction:
            return "In Production"

        case .postProduction:
            return "Post Production"

        case .released:
            return "Released"

        case .canceled:
            return "Canceled"

        case .other(let value):
            return value
        }
    }

    init(rawText: String) {
        switch rawText {
        case "Rumored":
            self = .rumored

        case "Planned":
            self = .planned

        case "In Production":
            self = .inProduction

        case "Post Production":
            self = .postProduction

        case "Released":
            self = .released

        case "Canceled":
            self = .canceled

        default:
            self = .other(rawText)
        }
    }
}
