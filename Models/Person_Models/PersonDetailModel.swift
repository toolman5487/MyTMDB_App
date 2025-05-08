//
//  PersonDetailModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/8.
//

import Foundation

struct PersonDetailModel: Decodable {
    let id: Int
    let name: String
    let adult: Bool
    let biography: String
    let birthday: String?
    let deathday: String?
    let gender: Int
    let homepage: String?
    let imdbId: String?
    let knownForDepartment: String
    let placeOfBirth: String?
    let popularity: Double
    let profilePath: String?
    let alsoKnownAs: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case adult
        case biography
        case birthday
        case deathday
        case gender
        case homepage
        case popularity
        case alsoKnownAs = "also_known_as"
        case imdbId = "imdb_id"
        case knownForDepartment = "known_for_department"
        case placeOfBirth = "place_of_birth"
        case profilePath = "profile_path"
    }
}
