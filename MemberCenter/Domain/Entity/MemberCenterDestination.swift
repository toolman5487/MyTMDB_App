//
//  MemberCenterDestination.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import Foundation

// MARK: - MemberCenterDestination

nonisolated enum MemberCenterDestination: String, Sendable, Equatable, CaseIterable, Identifiable {
    case favoriteMovies
    case favoriteTV
    case watchlistMovies
    case watchlistTV
    case ratedMovies
    case ratedTV
    case ratedEpisodes
    case lists

    var id: Self { self }

    var mediaKind: MediaKind? {
        switch self {
        case .favoriteMovies, .watchlistMovies, .ratedMovies:
            return .movie

        case .favoriteTV, .watchlistTV, .ratedTV:
            return .tv

        case .ratedEpisodes, .lists:
            return nil
        }
    }
}
