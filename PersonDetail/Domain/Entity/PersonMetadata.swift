//
//  PersonMetadata.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - PersonImages

nonisolated struct PersonImages: Sendable, Equatable, Identifiable {
    let id: Int
    let profiles: [PersonProfileImage]

    static func empty(id: Int) -> PersonImages {
        PersonImages(id: id, profiles: [])
    }
}

// MARK: - PersonProfileImage

nonisolated struct PersonProfileImage: Sendable, Equatable {
    let aspectRatio: Double
    let filePath: String
    let height: Int
    let languageCode: String?
    let voteAverage: Double
    let voteCount: Int
    let width: Int
}

// MARK: - PersonExternalIDs

nonisolated struct PersonExternalIDs: Sendable, Equatable, Identifiable {
    let id: Int
    let facebookID: String?
    let freebaseID: String?
    let freebaseMID: String?
    let imdbID: String?
    let instagramID: String?
    let tiktokID: String?
    let twitterID: String?
    let wikidataID: String?
    let youtubeID: String?

    static func empty(id: Int) -> PersonExternalIDs {
        PersonExternalIDs(
            id: id,
            facebookID: nil,
            freebaseID: nil,
            freebaseMID: nil,
            imdbID: nil,
            instagramID: nil,
            tiktokID: nil,
            twitterID: nil,
            wikidataID: nil,
            youtubeID: nil
        )
    }
}
