//
//  MovieDetailModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/6.
//

import Foundation

struct MovieDetailModel: Codable {
    let id: Int
    let adult: Bool
    let backdropPath: String?
    let posterPath: String?
    let title: String
    let releaseDate: String
    let runtime: Int
    let overview: String
    let popularity: Double
    let voteAverage: Double
    let voteCount: Int
    let budget: Int
    let revenue: Int
    let productionCompanies: [ProductionCompany]

    enum CodingKeys: String, CodingKey {
        case id
        case adult
        case backdropPath = "backdrop_path"
        case posterPath = "poster_path"
        case title
        case releaseDate = "release_date"
        case runtime
        case overview
        case popularity
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case budget
        case revenue
        case productionCompanies = "production_companies"
    }
}

struct ProductionCompany: Codable {
    let id: Int
    let name: String
    let logoPath: String?
    let originCountry: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case logoPath = "logo_path"
        case originCountry = "origin_country"
    }
}
