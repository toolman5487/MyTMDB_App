//
//  MovieSearchModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/20.
//

import Foundation

struct MovieSearchResponse: Codable {
    let page: Int
    let results: [Movie]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages  = "total_pages"
        case totalResults = "total_results"
    }
}

struct Movie: Codable, Identifiable {
    let id: Int
    let title: String
    let originalTitle: String
    let originalLanguage: String
    let overview: String
    let popularity: Double
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let adult: Bool
    let video: Bool
    let voteAverage: Double
    let voteCount: Int
    let genreIDs: [Int]

    enum CodingKeys: String, CodingKey {
        case id, title, overview, popularity, adult, video
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case originalTitle = "original_title"
        case originalLanguage = "original_language"
        case genreIDs = "genre_ids"
    }
}




