//
//  MovieGridModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - MovieGridMovie

nonisolated struct MovieGridMovie: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let voteCount: Int
    let popularity: Double

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case popularity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "未命名"
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        self.releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
    }
}

// MARK: - MovieGridMovieItem

nonisolated struct MovieGridMovieItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterURL: URL?
    let releaseDate: String?
    let voteAverage: Double
    let voteCount: Int
    let popularity: Double
    let releaseDateText: String
    let scoreText: String

    init(movie: MovieGridMovie) {
        let releaseDate = movie.releaseDate?.isEmpty == false ? movie.releaseDate : nil

        self.id = movie.id
        self.title = movie.title
        self.overview = movie.overview.isEmpty ? "目前沒有簡介。" : movie.overview
        self.posterURL = movie.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
        self.releaseDate = releaseDate
        self.voteAverage = movie.voteAverage
        self.voteCount = movie.voteCount
        self.popularity = movie.popularity
        self.releaseDateText = releaseDate ?? "尚未公布"
        self.scoreText = String(format: "%.1f", movie.voteAverage)
    }
}

// MARK: - MovieSortOption

nonisolated enum MovieSortOption: CaseIterable, Sendable, Hashable, Identifiable, AppSortMenuOption {
    case popularity
    case ratingHighToLow
    case ratingLowToHigh
    case newestRelease
    case oldestRelease
    case titleAscending
    case titleDescending

    var id: MovieSortOption {
        self
    }

    var title: String {
        switch self {
        case .popularity:
            return "人氣最高"

        case .ratingHighToLow:
            return "評分最高"

        case .ratingLowToHigh:
            return "評分最低"

        case .newestRelease:
            return "最新發布"

        case .oldestRelease:
            return "最早發布"

        case .titleAscending:
            return "名稱 (A → Z)"

        case .titleDescending:
            return "名稱 (Z → A)"
        }
    }

    func sorted(_ movies: [MovieGridMovieItem]) -> [MovieGridMovieItem] {
        switch self {
        case .popularity:
            return movies.sorted { lhs, rhs in
                if lhs.popularity != rhs.popularity {
                    return lhs.popularity > rhs.popularity
                }

                return Self.isTitleAscending(lhs, rhs)
            }

        case .ratingHighToLow:
            return movies.sorted { lhs, rhs in
                if lhs.voteAverage != rhs.voteAverage {
                    return lhs.voteAverage > rhs.voteAverage
                }

                if lhs.voteCount != rhs.voteCount {
                    return lhs.voteCount > rhs.voteCount
                }

                return Self.isTitleAscending(lhs, rhs)
            }

        case .ratingLowToHigh:
            return movies.sorted { lhs, rhs in
                if lhs.voteAverage != rhs.voteAverage {
                    return lhs.voteAverage < rhs.voteAverage
                }

                if lhs.voteCount != rhs.voteCount {
                    return lhs.voteCount > rhs.voteCount
                }

                return Self.isTitleAscending(lhs, rhs)
            }

        case .newestRelease:
            return movies.sorted { lhs, rhs in
                if let result = Self.compareReleaseDate(lhs, rhs, ascending: false) {
                    return result
                }

                return Self.isTitleAscending(lhs, rhs)
            }

        case .oldestRelease:
            return movies.sorted { lhs, rhs in
                if let result = Self.compareReleaseDate(lhs, rhs, ascending: true) {
                    return result
                }

                return Self.isTitleAscending(lhs, rhs)
            }

        case .titleAscending:
            return movies.sorted(by: Self.isTitleAscending)

        case .titleDescending:
            return movies.sorted { lhs, rhs in
                let comparison = lhs.title.localizedStandardCompare(rhs.title)
                if comparison != .orderedSame {
                    return comparison == .orderedDescending
                }

                return lhs.id < rhs.id
            }
        }
    }

    private static func compareReleaseDate(
        _ lhs: MovieGridMovieItem,
        _ rhs: MovieGridMovieItem,
        ascending: Bool
    ) -> Bool? {
        switch (lhs.releaseDate, rhs.releaseDate) {
        case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
            return ascending ? lhsDate < rhsDate : lhsDate > rhsDate

        case (.some, nil):
            return true

        case (nil, .some):
            return false

        default:
            return nil
        }
    }

    private static func isTitleAscending(
        _ lhs: MovieGridMovieItem,
        _ rhs: MovieGridMovieItem
    ) -> Bool {
        let comparison = lhs.title.localizedStandardCompare(rhs.title)
        if comparison != .orderedSame {
            return comparison == .orderedAscending
        }

        return lhs.id < rhs.id
    }
}
