//
//  TVSeries.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - TVSeries

nonisolated struct TVSeries: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let originalName: String
    let tagline: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let creators: [Creator]
    let episodeRunTimes: [Duration]
    let firstAirDate: CalendarDay?
    let lastAirDate: CalendarDay?
    let genres: [Genre]
    let networks: [Network]
    let productionCompanies: [ProductionCompany]
    let seasons: [TVSeason]
    let lastEpisodeToAir: TVEpisode?
    let nextEpisodeToAir: TVEpisode?
    let numberOfSeasons: Int
    let numberOfEpisodes: Int
    let isInProduction: Bool
    let status: TVStatus
    let type: String
    let voteAverage: Double
    let voteCount: Int
    let homepage: URL?
}

// MARK: - TVSeason

nonisolated struct TVSeason: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let airDate: CalendarDay?
    let episodeCount: Int
    let posterPath: String?
    let seasonNumber: Int
    let voteAverage: Double
}

// MARK: - TVEpisode

nonisolated struct TVEpisode: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let airDate: CalendarDay?
    let episodeNumber: Int
    let seasonNumber: Int
    let stillPath: String?
    let voteAverage: Double
}

// MARK: - Network

nonisolated struct Network: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let logoPath: String?
    let originCountry: String
}

// MARK: - Creator

nonisolated struct Creator: Sendable, Equatable, Identifiable {
    let id: Int
    let creditID: String
    let name: String
    let profilePath: String?
}

// MARK: - TVStatus

nonisolated enum TVStatus: Sendable, Equatable {
    case returningSeries
    case planned
    case inProduction
    case ended
    case canceled
    case pilot
    case other(String)

    var rawText: String {
        switch self {
        case .returningSeries:
            return "Returning Series"

        case .planned:
            return "Planned"

        case .inProduction:
            return "In Production"

        case .ended:
            return "Ended"

        case .canceled:
            return "Canceled"

        case .pilot:
            return "Pilot"

        case .other(let value):
            return value
        }
    }

    init(rawText: String) {
        switch rawText {
        case "Returning Series":
            self = .returningSeries

        case "Planned":
            self = .planned

        case "In Production":
            self = .inProduction

        case "Ended":
            self = .ended

        case "Canceled":
            self = .canceled

        case "Pilot":
            self = .pilot

        default:
            self = .other(rawText)
        }
    }
}
