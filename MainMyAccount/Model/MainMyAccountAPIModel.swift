//
//  MainMyAccountAPIModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Foundation

// MARK: - MainMyAccountProfileResponse

struct MainMyAccountProfileResponse: Decodable, Sendable, Equatable {
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
    struct Avatar: Decodable, Sendable, Equatable {
        let gravatar: Gravatar
        let tmdb: TMDBAvatar
    }
}

// MARK: - MainMyAccountProfileResponse.Avatar.Gravatar

extension MainMyAccountProfileResponse.Avatar {
    struct Gravatar: Decodable, Sendable, Equatable {
        let hash: String
    }

    struct TMDBAvatar: Decodable, Sendable, Equatable {
        let avatarPath: String?

        enum CodingKeys: String, CodingKey {
            case avatarPath = "avatar_path"
        }
    }
}

// MARK: - Display Helpers

extension MainMyAccountProfileResponse {

    var displayName: String {
        if let name, !name.isEmpty {
            return name
        }
        return username
    }

    var avatarURL: URL? {
        if let path = avatar.tmdb.avatarPath {
            return APIConfig.tmdbImageURL(path: path)
        }
        return APIConfig.gravatarURL(hash: avatar.gravatar.hash)
    }

    var regionDescription: String {
        "\(languageCode.uppercased()) · \(countryCode.uppercased())"
    }
}

// MARK: - MainMyAccountProfileItem

struct MainMyAccountProfileItem: Hashable {
    let id: Int
    let displayName: String
    let username: String
    let avatarURL: URL?
    let regionDescription: String

    init(profile: MainMyAccountProfileResponse) {
        id = profile.id
        displayName = profile.displayName
        username = profile.username
        avatarURL = profile.avatarURL
        regionDescription = profile.regionDescription
    }
}
