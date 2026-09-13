//
//  AccountMediaRatingTarget.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - AccountMediaRatingTarget

nonisolated enum AccountMediaRatingTarget: Sendable, Equatable {
    case movie(id: Int)
    case tv(seriesID: Int)
    case episode(seriesID: Int, seasonNumber: Int, episodeNumber: Int)
}

extension AccountMediaRatingTarget {

    var isValid: Bool {
        switch self {
        case .movie(let id):
            return id > 0

        case .tv(let seriesID):
            return seriesID > 0

        case .episode(let seriesID, let seasonNumber, let episodeNumber):
            return seriesID > 0 && seasonNumber >= 0 && episodeNumber > 0
        }
    }
}
