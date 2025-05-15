//
//  FavoriteResponse.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/15.
//

import Foundation

struct FavoriteResponse: Decodable {
    let status_code: Int
    let status_message: String
}

struct AccountState: Decodable {
    let id: Int
    let favorite: Bool
    let rated: Rated?
    let watchlist: Bool

    struct Rated: Decodable {
        let value: Double?
    }
}
