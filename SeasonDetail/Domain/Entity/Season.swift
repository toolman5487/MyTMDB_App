//
//  Season.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - Season

nonisolated struct Season: Sendable, Equatable, Identifiable {
    let id: Int
    let tmdbInternalID: String
    let name: String
    let overview: String
    let airDate: CalendarDay?
    let episodes: [SeasonEpisode]
    let posterPath: String?
    let seasonNumber: Int
    let voteAverage: Double
}

// MARK: - SeasonEpisode

nonisolated struct SeasonEpisode: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let airDate: CalendarDay?
    let episodeNumber: Int
    let episodeType: String
    let productionCode: String
    let runtime: Duration?
    let seasonNumber: Int
    let showID: Int
    let stillPath: String?
    let voteAverage: Double
    let voteCount: Int
    let crew: [SeasonEpisodeCrewMember]
    let guestStars: [SeasonEpisodeGuestStar]
}

// MARK: - SeasonEpisodeCrewMember

nonisolated struct SeasonEpisodeCrewMember: Sendable, Equatable, Identifiable {
    let id: Int
    let creditID: String
    let department: String
    let job: String
    let name: String
    let originalName: String
    let profilePath: String?
}

// MARK: - SeasonEpisodeGuestStar

nonisolated struct SeasonEpisodeGuestStar: Sendable, Equatable, Identifiable {
    let id: Int
    let character: String
    let creditID: String
    let name: String
    let order: Int
    let profilePath: String?
}
