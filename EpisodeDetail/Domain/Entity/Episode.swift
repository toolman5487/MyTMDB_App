//
//  Episode.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - EpisodeDetailInput

nonisolated struct EpisodeDetailInput: Sendable, Equatable {
    let seriesID: Int
    let seasonNumber: Int
    let episodeNumber: Int

    var isValid: Bool {
        seriesID > 0 && seasonNumber >= 0 && episodeNumber > 0
    }
}

// MARK: - Episode

nonisolated struct Episode: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let airDate: CalendarDay?
    let crew: [EpisodeCrewMember]
    let episodeNumber: Int
    let guestStars: [EpisodeCastMember]
    let productionCode: String
    let runtime: Duration?
    let seasonNumber: Int
    let stillPath: String?
    let voteAverage: Double
    let voteCount: Int
}

// MARK: - EpisodeCastMember

nonisolated struct EpisodeCastMember: Sendable, Equatable, Identifiable {
    let id: Int
    let character: String
    let creditID: String
    let name: String
    let order: Int
    let profilePath: String?
}

// MARK: - EpisodeCrewMember

nonisolated struct EpisodeCrewMember: Sendable, Equatable, Identifiable {
    let id: Int
    let creditID: String
    let department: String
    let job: String
    let name: String
    let profilePath: String?
}
