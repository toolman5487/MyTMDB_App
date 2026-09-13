//
//  PersonDetailContent.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - PersonDetailContent

nonisolated struct PersonDetailContent: Sendable, Equatable {
    let detail: Person
    let combinedCredits: PersonCredits
    let images: PersonImages
    let externalIDs: PersonExternalIDs
}
