//
//  SeasonCredits.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - SeasonCredits

nonisolated struct SeasonCredits: Sendable, Equatable, Identifiable {
    let id: Int
    let cast: [SeasonCreditCast]
    let crew: [SeasonCreditCrew]
    let guestStars: [SeasonCreditCast]

    static func empty(id: Int) -> SeasonCredits {
        SeasonCredits(id: id, cast: [], crew: [], guestStars: [])
    }
}

// MARK: - SeasonCreditCast

nonisolated struct SeasonCreditCast: Sendable, Equatable, Identifiable {
    let id: Int
    let character: String
    let creditID: String
    let name: String
    let order: Int
    let profilePath: String?
}

// MARK: - SeasonCreditCrew

nonisolated struct SeasonCreditCrew: Sendable, Equatable, Identifiable {
    let id: Int
    let creditID: String
    let department: String
    let job: String
    let name: String
    let profilePath: String?
}
