//
//  PersonDetailProviding.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - PersonDetailProviding

nonisolated protocol PersonDetailProviding: Sendable {
    func person(id: Int) async throws -> Person
    func combinedCredits(personID: Int) async throws -> PersonCredits
    func movieCredits(personID: Int) async throws -> PersonCredits
    func tvCredits(personID: Int) async throws -> PersonCredits
    func images(personID: Int) async throws -> PersonImages
    func externalIDs(personID: Int) async throws -> PersonExternalIDs
}
