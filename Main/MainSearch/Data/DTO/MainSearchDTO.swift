//
//  MainSearchDTO.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - MainSearchResultDTO

nonisolated struct MainSearchResultDTO: Decodable, Sendable {
    let id: Int
    let mediaType: String?
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let profilePath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let voteCount: Int?
    let popularity: Double?
    let knownForDepartment: String?

    enum CodingKeys: String, CodingKey {
        case id
        case mediaType = "media_type"
        case title
        case name
        case overview
        case posterPath = "poster_path"
        case profilePath = "profile_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case popularity
        case knownForDepartment = "known_for_department"
    }
}

// MARK: - MainSearchPopularPersonDTO

nonisolated struct MainSearchPopularPersonDTO: Decodable, Sendable {
    let id: Int
    let name: String?
    let profilePath: String?
    let knownForDepartment: String?
    let popularity: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case profilePath = "profile_path"
        case knownForDepartment = "known_for_department"
        case popularity
    }
}
