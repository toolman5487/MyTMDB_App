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

    // MARK: - Website URL

    static func movie(id: Int) -> URL? {
        guard id > 0 else { return nil }
        return URL(string: "\(websiteBaseURL)/movie/\(id)")
    }

    static func tvSeries(id: Int) -> URL? {
        guard id > 0 else { return nil }
        return URL(string: "\(websiteBaseURL)/tv/\(id)")
    }

    static func season(
        seriesID: Int,
        seasonNumber: Int
    ) -> URL? {
        guard seasonNumber >= 0, let seriesURL = tvSeries(id: seriesID) else { return nil }
        return URL(string: "\(seriesURL.absoluteString)/season/\(seasonNumber)")
    }

    static func episode(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) -> URL? {
        guard
            episodeNumber > 0,
            let seasonURL = season(seriesID: seriesID, seasonNumber: seasonNumber)
        else { return nil }
        return URL(string: "\(seasonURL.absoluteString)/episode/\(episodeNumber)")
    }
}
