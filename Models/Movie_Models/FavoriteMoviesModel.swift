//
//  FavoriteMoviesModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/9.
//

import Foundation

struct FavoriteMovieItem: Decodable {
    let id: Int
    let title: String
    let posterPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let rating: Double?

    enum CodingKeys: String, CodingKey {
        case id, title
        case posterPath   = "poster_path"
        case releaseDate  = "release_date"
        case voteAverage  = "vote_average"
        case rating
    }
}

struct FavoriteMoviesResponse: Decodable {
    let page: Int
       let results: [FavoriteMovieItem]
       let totalPages: Int
       let totalResults: Int
       enum CodingKeys: String, CodingKey {
           case page, results
           case totalPages   = "total_pages"
           case totalResults = "total_results"
       }
}
