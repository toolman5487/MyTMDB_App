//
//  EpisodeModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/12.
//

import Foundation

struct EpisodeModel: Codable {
    let id: Int
    let episodeNumber: Int
    let name: String
    let overview: String
    let airDate: String?
    let seasonNumber: Int?
    let showId: Int?
    let episodeType: String?
    let productionCode: String?
    let runtime: Int?
    let stillPath: String?
    let voteAverage: Double?
    let voteCount: Int?
    let crew: [CrewMember]?
    let guestStars: [GuestStar]?

    enum CodingKeys: String, CodingKey {
        case id
        case episodeNumber = "episode_number"
        case name, overview
        case airDate = "air_date"
        case seasonNumber = "season_number"
        case showId = "show_id"
        case episodeType = "episode_type"
        case productionCode = "production_code"
        case runtime
        case stillPath = "still_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case crew
        case guestStars = "guest_stars"
    }
}

struct CrewMember: Codable {
    let job: String?
    let department: String?
    let creditId: String?
    let id: Int
    let name: String
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case job, department
        case creditId = "credit_id"
        case id, name
        case profilePath = "profile_path"
    }
}

struct GuestStar: Codable {
    let id: Int
    let name: String
    let character: String?
    let order: Int?
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, character, order
        case profilePath = "profile_path"
    }
}

struct SeasonDetailResponse: Decodable {
    let episodes: [EpisodeModel]
}
