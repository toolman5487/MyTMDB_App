//
//  TMDBResourceURL.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - TMDBResourceURL

nonisolated enum TMDBResourceURL {

    // MARK: - Base URL

    static let websiteBaseURL = "https://www.themoviedb.org"
    static let imageBaseURL = "https://image.tmdb.org/t/p"
    static let gravatarBaseURL = "https://www.gravatar.com/avatar"

    // MARK: - ImageSize

    enum ImageSize: String {
        case w185
        case w500
    }

    // MARK: - Resource URL

    static func image(path: String, size: ImageSize = .w185) -> URL? {
        guard !path.isEmpty else { return nil }
        return URL(string: "\(imageBaseURL)/\(size.rawValue)\(path)")
    }

    static func gravatar(hash: String, size: Int = 185) -> URL? {
        guard !hash.isEmpty else { return nil }
        return URL(string: "\(gravatarBaseURL)/\(hash)?s=\(size)&d=identicon")
    }

    static var signup: URL? {
        URL(string: "\(websiteBaseURL)/signup")
    }
}
