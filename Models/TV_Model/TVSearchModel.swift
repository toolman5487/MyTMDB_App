//
//  TVSearchModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/22.
//

import Foundation


struct TVSearchResponse: Codable {
    let page: Int
    let results: [TVShow]
    let totalPages: Int
    let totalResults: Int

    private enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages   = "total_pages"
        case totalResults = "total_results"
    }
}


struct TVShow: Codable, Hashable {
    let adult: Bool
    let backdropPath: String?
    let genreIDs: [Int]
    let id: Int
    let originCountry: [String]
    let originalLanguage: String
    let originalName: String
    let overview: String
    let popularity: Double
    let posterPath: String?
    let firstAirDate: String
    let name: String
    let voteAverage: Double
    let voteCount: Int

    private enum CodingKeys: String, CodingKey {
        case adult
        case backdropPath = "backdrop_path"
        case genreIDs = "genre_ids"
        case id
        case originCountry = "origin_country"
        case originalLanguage = "original_language"
        case originalName = "original_name"
        case overview
        case popularity
        case posterPath = "poster_path"
        case firstAirDate = "first_air_date"
        case name
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
}
