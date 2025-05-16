//
//  FavoriteResponse.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/15.
//

import Foundation

struct FavoriteResponse: Codable {
    let status_code: Int
    let status_message: String
}

struct AccountState: Codable {
    let id: Int
    let favorite: Bool
    let rated: Rated?
    let watchlist: Bool

    struct Rated: Codable {
        let value: Double?
    }
}
