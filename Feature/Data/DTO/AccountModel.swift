//
//  AccountModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/5.
//

import Foundation

nonisolated struct Account: Codable, Sendable {
    let id: Int
    let name: String?
    let username: String
    let include_adult: Bool
    let iso_639_1: String
    let iso_3166_1: String
    let avatar: Avatar

    nonisolated struct Avatar: Codable, Sendable {
        let gravatar: Gravatar
        let tmdb: TMDBAvatar

        nonisolated struct Gravatar: Codable, Sendable {
            let hash: String
        }

        nonisolated struct TMDBAvatar: Codable, Sendable {
            let avatar_path: String?
        }
    }
}
