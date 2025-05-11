//
//  FavoriteTVResponse.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/9.
//


import Foundation

struct FavoriteTVItem: Decodable {
    let id: Int
    let name: String
    let posterPath: String?
    let firstAirDate: String?
    let voteAverage: Double
    let voteCount: Int
    let rating: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case posterPath = "poster_path"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case rating
    }
}

struct FavoriteTVResponseModel: Decodable {
    let page: Int
    let results: [FavoriteTVItem]
    let totalPages: Int
    let totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages   = "total_pages"
        case totalResults = "total_results"
    }
}

