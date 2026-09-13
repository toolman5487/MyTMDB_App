//
//  HomeCategory.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Foundation

// MARK: - HomeCategory

nonisolated enum HomeCategory: CaseIterable, Codable, Sendable, Equatable, Identifiable {
    case trendingMovies
    case trendingTV
    case popularMovies
    case popularTV
    case nowPlayingMovies
    case onTheAirTV
    case upcomingMovies
    case airingTodayTV
    case topRatedMovies
    case topRatedTV

    var id: Self { self }

    var mediaType: MediaKind {
        switch self {
        case .trendingMovies, .popularMovies, .nowPlayingMovies, .upcomingMovies, .topRatedMovies:
            return .movie

        case .trendingTV, .popularTV, .onTheAirTV, .airingTodayTV, .topRatedTV:
            return .tv
        }
    }
}
