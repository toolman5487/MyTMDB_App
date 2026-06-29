//
//  MainMyAccountAPIModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Foundation

// MARK: - MainMyAccountProfileResponse

struct MainMyAccountProfileResponse: Decodable, Sendable {
    let id: Int
    let name: String?
    let username: String
    let isAdultContentIncluded: Bool
    let languageCode: String
    let countryCode: String
    let avatar: Avatar

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case username
        case isAdultContentIncluded = "include_adult"
        case languageCode = "iso_639_1"
        case countryCode = "iso_3166_1"
        case avatar
    }
}

// MARK: - MainMyAccountProfileResponse.Avatar

extension MainMyAccountProfileResponse {
    struct Avatar: Decodable, Sendable {
        let gravatar: Gravatar
        let tmdb: TMDBAvatar
    }
}

// MARK: - MainMyAccountProfileResponse.Avatar.Gravatar

extension MainMyAccountProfileResponse.Avatar {
    struct Gravatar: Decodable, Sendable {
        let hash: String
    }

    struct TMDBAvatar: Decodable, Sendable {
        let avatarPath: String?

        enum CodingKeys: String, CodingKey {
            case avatarPath = "avatar_path"
        }
    }
}
