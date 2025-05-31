//
//  MovieAccountStatesModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/28.
//

import Foundation

struct MovieAccountState: Decodable {
    let id: Int
    let favorite: Bool
    let rated: Rated?
    let watchlist: Bool

    struct Rated: Decodable {
        let value: Double
    }
}

