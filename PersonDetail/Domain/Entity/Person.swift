//
//  Person.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - Person

nonisolated struct Person: Sendable, Equatable, Identifiable {
    let id: Int
    let adult: Bool
    let alsoKnownAs: [String]
    let biography: String?
    let birthday: CalendarDay?
    let deathday: CalendarDay?
    let gender: PersonGender
    let homepage: URL?
    let imdbID: String?
    let knownForDepartment: String?
    let name: String
    let placeOfBirth: String?
    let popularity: Double
    let profilePath: String?
}

// MARK: - PersonGender

nonisolated enum PersonGender: Sendable, Equatable {
    case notSpecified
    case female
    case male
    case nonBinary
    case unknown(Int)
}
