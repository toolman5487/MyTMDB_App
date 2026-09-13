//
//  SeasonMetadata.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - SeasonExternalIDs

nonisolated struct SeasonExternalIDs: Sendable, Equatable, Identifiable {
    let id: Int
    let freebaseMID: String?
    let freebaseID: String?
    let tvdbID: Int?
    let tvrageID: Int?
    let wikidataID: String?

    static func empty(id: Int) -> SeasonExternalIDs {
        SeasonExternalIDs(
            id: id,
            freebaseMID: nil,
            freebaseID: nil,
            tvdbID: nil,
            tvrageID: nil,
            wikidataID: nil
        )
    }
}

// MARK: - SeasonTranslations

nonisolated struct SeasonTranslations: Sendable, Equatable, Identifiable {
    let id: Int
    let items: [SeasonTranslation]

    static func empty(id: Int) -> SeasonTranslations {
        SeasonTranslations(id: id, items: [])
    }
}

nonisolated struct SeasonTranslation: Sendable, Equatable, Identifiable {
    var id: String {
        "\(languageCode)-\(countryCode)-\(name)"
    }

    let countryCode: String
    let languageCode: String
    let name: String
    let englishName: String
    let content: SeasonTranslationContent
}

nonisolated struct SeasonTranslationContent: Sendable, Equatable {
    let name: String
    let overview: String
    let homepage: URL?
}

// MARK: - SeasonAccountState

nonisolated struct SeasonAccountState: Sendable, Equatable, Identifiable {
    let id: Int
    let rating: SeasonRatingState

    static func unrated(id: Int) -> SeasonAccountState {
        SeasonAccountState(id: id, rating: .unrated)
    }
}

nonisolated enum SeasonRatingState: Sendable, Equatable {
    case unrated
    case rated(Double)
}

// MARK: - SeasonAccountCredential

nonisolated enum SeasonAccountCredential: Sendable, Equatable {
    case guest(sessionID: String)
    case user(sessionID: String)
}
