//
//  TVDetailModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/6.
//

import Foundation

struct TVDetailModel: Decodable {
    let id: Int
    let name: String
    let originalName: String
    let overview: String
    let firstAirDate: String?
    let lastAirDate: String?
    let inProduction: Bool
    let episodeRunTime: [Int]
    let numberOfEpisodes: Int
    let numberOfSeasons: Int
    let genres: [Genre]
    let languages: [String]
    let originCountry: [String]
    let status: String
    let type: String
    let popularity: Double
    let voteAverage: Double
    let voteCount: Int
    let backdropPath: String?
    let posterPath: String?
    let homepage: String?
    let createdBy: [CreatedBy]
    let networks: [Network]
    let productionCompanies: [TVProductionCompany]
    let seasons: [Season]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case originalName = "original_name"
        case overview
        case firstAirDate = "first_air_date"
        case lastAirDate = "last_air_date"
        case inProduction = "in_production"
        case episodeRunTime  = "episode_run_time"
        case numberOfEpisodes = "number_of_episodes"
        case numberOfSeasons = "number_of_seasons"
        case genres
        case languages = "languages"
        case originCountry = "origin_country"
        case status
        case type
        case popularity
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case backdropPath = "backdrop_path"
        case posterPath = "poster_path"
        case homepage
        case createdBy = "created_by"
        case networks
        case productionCompanies = "production_companies"
        case seasons
    }
}

struct Genre: Decodable {
    let id: Int
    let name: String
}

struct CreatedBy: Decodable {
    let id: Int
    let creditID: String
    let name: String
    let gender: Int?
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, gender
        case creditID    = "credit_id"
        case profilePath = "profile_path"
    }
}

struct Network: Decodable {
    let id: Int
    let name: String
    let logoPath: String?
    let originCountry: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case logoPath = "logo_path"
        case originCountry = "origin_country"
    }
}

struct TVProductionCompany: Decodable {
    let id: Int
    let name: String
    let logoPath: String?
    let originCountry: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case logoPath     = "logo_path"
        case originCountry = "origin_country"
    }
}

struct Season: Decodable {
    let id: Int
    let name: String
    let overview: String?
    let airDate: String?
    let seasonNumber: Int
    let episodeCount: Int
    let posterPath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case airDate = "air_date"
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
        case posterPath = "poster_path"
    }
}
