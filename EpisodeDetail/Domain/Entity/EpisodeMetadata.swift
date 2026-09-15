//
//  EpisodeMetadata.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - EpisodeImages

nonisolated struct EpisodeImages: Sendable, Equatable, Identifiable {
    let id: Int
    let stills: [MediaImage]

    static func empty(id: Int) -> EpisodeImages {
        EpisodeImages(id: id, stills: [])
    }
}

// MARK: - EpisodeExternalIDs

nonisolated struct EpisodeExternalIDs: Sendable, Equatable, Identifiable {
    let id: Int
    let imdbID: String?
    let freebaseMID: String?
    let freebaseID: String?
    let tvdbID: Int?
    let tvrageID: Int?
    let wikidataID: String?

    static func empty(id: Int) -> EpisodeExternalIDs {
        EpisodeExternalIDs(
            id: id,
            imdbID: nil,
            freebaseMID: nil,
            freebaseID: nil,
            tvdbID: nil,
            tvrageID: nil,
            wikidataID: nil
        )
    }
}

// MARK: - EpisodeTranslations

nonisolated struct EpisodeTranslations: Sendable, Equatable, Identifiable {
    let id: Int
    let items: [EpisodeTranslation]

    static func empty(id: Int) -> EpisodeTranslations {
        EpisodeTranslations(id: id, items: [])
    }
}

nonisolated struct EpisodeTranslation: Sendable, Equatable, Identifiable {
    var id: String {
        "\(languageCode)-\(countryCode)-\(name)"
    }

    let countryCode: String
    let languageCode: String
    let name: String
    let englishName: String
    let content: EpisodeTranslationContent
}

nonisolated struct EpisodeTranslationContent: Sendable, Equatable {
    let name: String
    let overview: String
}

// MARK: - EpisodeAccountState

nonisolated struct EpisodeAccountState: Sendable, Equatable, Identifiable {
    let id: Int
    let rating: EpisodeRatingState

    static func unrated(id: Int) -> EpisodeAccountState {
        EpisodeAccountState(id: id, rating: .unrated)
    }
}

nonisolated enum EpisodeRatingState: Sendable, Equatable {
    case unrated
    case rated(Double)

    var value: Double? {
        switch self {
        case .unrated:
            return nil

        case .rated(let value):
            return value
        }
    }
}

// MARK: - EpisodeAccountCredential

nonisolated enum EpisodeAccountCredential: Sendable, Equatable {
    case guest(sessionID: String)
    case user(sessionID: String)
}
