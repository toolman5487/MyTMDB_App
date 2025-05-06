//
//  MultiSearchResultModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/5.

import Foundation

struct MultiSearchResult: Decodable {
    enum MediaType: String, Decodable {
        case movie, tv, person
    }

    let id: Int
    let mediaType: MediaType
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let profilePath: String?
    let releaseDate: String?
    let firstAirDate: String?

    private enum CodingKeys: String, CodingKey {
        case id, overview, title, name
        case mediaType     = "media_type"
        case posterPath    = "poster_path"
        case backdropPath  = "backdrop_path"
        case profilePath   = "profile_path"
        case releaseDate   = "release_date"
        case firstAirDate  = "first_air_date"
    }
}

struct MultiSearchResponse: Decodable {
    let page: Int
    let results: [MultiSearchResult]
    let totalResults: Int
    let totalPages: Int

    private enum CodingKeys: String, CodingKey {
        case page, results
        case totalResults = "total_results"
        case totalPages   = "total_pages"
    }
}
