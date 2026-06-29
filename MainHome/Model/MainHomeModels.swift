//
//  MainHomeModels.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Foundation

// MARK: - MainHomeMovieCategory

nonisolated enum MainHomeMovieCategory: CaseIterable, Codable, Sendable, Equatable {
    case trendingToday
    case popular
    case nowPlaying
    case upcoming
    case topRated
}

// MARK: - MainHomeMoviePage

nonisolated struct MainHomeMoviePage: Codable, Sendable, Equatable {
    let category: MainHomeMovieCategory
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let movies: [MainHomeMovie]
}

// MARK: - MainHomeMovieSection

nonisolated struct MainHomeMovieSection: Codable, Sendable, Equatable {
    let category: MainHomeMovieCategory
    let totalResults: Int
    let movies: [MainHomeMovie]
}

// MARK: - MainHomeMovie

nonisolated struct MainHomeMovie: Codable, Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let voteCount: Int
    let popularity: Double

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case popularity
    }
}

// MARK: - TMDBPageResponse

nonisolated struct TMDBPageResponse<Result: Codable & Sendable>: Codable, Sendable {
    let page: Int
    let results: [Result]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}
