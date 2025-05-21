//
//  AllTrendingModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/20.
//

import Foundation

struct TrendingResponse: Codable {
    let page: Int
    let results: [TrendingItem]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct TrendingItem: Codable {
    let backdropPath: String?
    let id: Int
    let mediaType: String
    let title: String?
    let name: String?
    let originalTitle: String?
    let originalName: String?
    let overview: String
    let posterPath: String?
    let genreIds: [Int]
    let popularity: Double
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double
    let voteCount: Int
    let adult: Bool
    let originalLanguage: String
    let originCountry: [String]?
    let video: Bool?

    enum CodingKeys: String, CodingKey {
        case id, title, overview, popularity, name, adult, video
        case backdropPath = "backdrop_path"
        case mediaType = "media_type"
        case originalTitle = "original_title"
        case originalName  = "original_name"
        case posterPath = "poster_path"
        case genreIds = "genre_ids"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case originalLanguage = "original_language"
        case originCountry = "origin_country"
    }
}

