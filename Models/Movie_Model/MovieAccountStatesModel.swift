//
//  MovieAccountStatesModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/28.
//

import Foundation

struct MovieAccountState: Codable {
    let id: Int
    let favorite: Bool
    let rated: Rated?
    let watchlist: Bool

    struct Rated: Codable {
        let value: Double
    }
}

