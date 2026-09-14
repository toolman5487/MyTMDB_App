//
//  AggregateCredits.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - AggregateCredits

nonisolated struct AggregateCredits: Sendable, Equatable {
    let cast: [AggregateCastMember]
    let crew: [AggregateCrewMember]

    static let empty = AggregateCredits(cast: [], crew: [])
}

// MARK: - AggregateCastMember

nonisolated struct AggregateCastMember: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let characters: [String]
    let episodeCount: Int
    let profilePath: String?
    let order: Int
}

// MARK: - AggregateCrewMember

nonisolated struct AggregateCrewMember: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let department: String
    let jobs: [String]
    let episodeCount: Int
    let profilePath: String?
}
