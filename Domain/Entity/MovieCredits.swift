//
//  MovieCredits.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - MovieCredits

nonisolated struct MovieCredits: Sendable, Equatable {
    let cast: [CastMember]
    let crew: [CrewMember]

    static let empty = MovieCredits(cast: [], crew: [])
}

// MARK: - CastMember

nonisolated struct CastMember: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let character: String
    let profilePath: String?
    let order: Int
}

// MARK: - CrewMember

nonisolated struct CrewMember: Sendable, Equatable, Identifiable {
    let id: Int
    let creditID: String
    let name: String
    let job: String
    let department: String
    let profilePath: String?
}
