//
//  Constants.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/6.
//

import Foundation
struct TMDB {
    static let apiKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "TMDBAPIKey") as? String,
              !key.isEmpty else {
            fatalError("TMDBAPIKey is missing from Info.plist")
        }
        return key
    }()

    static let baseURL = "https://api.themoviedb.org/3"
}
