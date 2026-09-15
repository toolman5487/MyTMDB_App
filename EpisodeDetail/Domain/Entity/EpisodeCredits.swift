//
//  EpisodeCredits.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - EpisodeCredits

nonisolated struct EpisodeCredits: Sendable, Equatable, Identifiable {
    let id: Int
    let cast: [EpisodeCastMember]
    let crew: [EpisodeCrewMember]
    let guestStars: [EpisodeCastMember]

    static func empty(id: Int) -> EpisodeCredits {
        EpisodeCredits(id: id, cast: [], crew: [], guestStars: [])
    }
}
