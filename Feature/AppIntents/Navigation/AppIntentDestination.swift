//
//  AppIntentDestination.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import Foundation

// MARK: - AppIntentDestination

nonisolated enum AppIntentDestination: Sendable, Equatable {
    case favoriteMovies
    case favoriteTV
    case movieDetail(id: Int)
    case tvDetail(id: Int)
    case login

    private enum URLValue {
        static let scheme = "cinebase"
        static let host = "intent"
    }

    init?(url: URL) {
        guard url.scheme == URLValue.scheme,
              url.host == URLValue.host else {
            return nil
        }

        let components = url.pathComponents.filter { $0 != "/" }
        if components == ["favorites", "movies"] {
            self = .favoriteMovies
        } else if components == ["favorites", "tv"] {
            self = .favoriteTV
        } else if components.count == 2,
                  components[0] == "movie",
                  let id = Int(components[1]),
                  id > 0 {
            self = .movieDetail(id: id)
        } else if components.count == 2,
                  components[0] == "tv",
                  let id = Int(components[1]),
                  id > 0 {
            self = .tvDetail(id: id)
        } else if components == ["login"] {
            self = .login
        } else {
            return nil
        }
    }

    var url: URL? {
        var components = URLComponents()
        components.scheme = URLValue.scheme
        components.host = URLValue.host
        components.path = path
        return components.url
    }

    private var path: String {
        switch self {
        case .favoriteMovies:
            return "/favorites/movies"

        case .favoriteTV:
            return "/favorites/tv"

        case .movieDetail(let id):
            return "/movie/\(id)"

        case .tvDetail(let id):
            return "/tv/\(id)"

        case .login:
            return "/login"
        }
    }
}
