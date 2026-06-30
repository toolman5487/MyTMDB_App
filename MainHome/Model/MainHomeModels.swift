//
//  MainHomeModels.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Foundation

// MARK: - MainHomeMediaType

nonisolated enum MainHomeMediaType: String, Codable, Sendable, Equatable {
    case movie
    case tv
}

// MARK: - MainHomeContentCategory

nonisolated enum MainHomeContentCategory: CaseIterable, Codable, Sendable, Equatable, Identifiable {
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

    var mediaType: MainHomeMediaType {
        switch self {
        case .trendingMovies, .popularMovies, .nowPlayingMovies, .upcomingMovies, .topRatedMovies:
            return .movie

        case .trendingTV, .popularTV, .onTheAirTV, .airingTodayTV, .topRatedTV:
            return .tv
        }
    }
}

// MARK: - MainHomeContentPage

nonisolated struct MainHomeContentPage: Sendable, Equatable {
    let category: MainHomeContentCategory
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let contents: [MainHomeContent]
}

// MARK: - MainHomeContentSection

nonisolated struct MainHomeContentSection: Sendable, Equatable {
    let category: MainHomeContentCategory
    let totalResults: Int
    let contents: [MainHomeContent]
}

// MARK: - MainHomeContent

nonisolated struct MainHomeContent: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let primaryDate: String?
    let voteAverage: Double
    let voteCount: Int
    let popularity: Double

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case name
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case popularity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? "未命名"
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        self.primaryDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
            ?? container.decodeIfPresent(String.self, forKey: .firstAirDate)
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
    }
}

// MARK: - TMDBPageResponse

nonisolated struct TMDBPageResponse<Result: Decodable & Sendable>: Decodable, Sendable {
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
