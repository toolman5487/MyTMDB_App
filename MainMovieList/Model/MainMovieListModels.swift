//
//  MainMovieListModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import Foundation

// MARK: - MainMovieGenreResponse

nonisolated struct MainMovieGenreResponse: Decodable, Sendable, Equatable {
    let genres: [MainMovieGenre]
}

// MARK: - MainMovieGenre

nonisolated struct MainMovieGenre: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - MainMovieListMoviePage

nonisolated struct MainMovieListMoviePage: Sendable, Equatable {
    let genreID: Int
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let movies: [MainMovieListMovie]
}

// MARK: - MainMovieSearchResultPage

nonisolated struct MainMovieSearchResultPage: Sendable, Equatable {
    let keyword: String
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let movies: [MainMovieListMovie]
}

// MARK: - MainMovieListMovie

nonisolated struct MainMovieListMovie: Decodable, Sendable, Equatable, Identifiable {
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

// MARK: - MainMovieGenreItem

nonisolated struct MainMovieGenreItem: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let isSelected: Bool

    init(
        genre: MainMovieGenre,
        isSelected: Bool
    ) {
        self.id = genre.id
        self.name = genre.name
        self.isSelected = isSelected
    }
}

// MARK: - MainMovieListMovieItem

nonisolated struct MainMovieListMovieItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterURL: URL?
    let releaseDate: String?
    let voteAverage: Double
    let voteCount: Int
    let releaseDateText: String
    let scoreText: String

    init(movie: MainMovieListMovie) {
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
        self.releaseDateText = releaseDate ?? "尚未公布"
        self.scoreText = String(format: "%.1f", movie.voteAverage)
    }
}

// MARK: - MainMovieSearchFilter

nonisolated enum MainMovieSearchFilter: CaseIterable, Sendable, Hashable, Identifiable {
    case relevance
    case highestRated
    case newestRelease
    case oldestRelease

    var id: Self { self }

    var title: String {
        switch self {
        case .relevance:
            return "相關度"

        case .highestRated:
            return "最高評分"

        case .newestRelease:
            return "最新上映"

        case .oldestRelease:
            return "最早上映"
        }
    }

    func sorted(_ movies: [MainMovieListMovieItem]) -> [MainMovieListMovieItem] {
        switch self {
        case .relevance:
            return movies

        case .highestRated:
            return movies.sorted { lhs, rhs in
                if lhs.voteAverage == rhs.voteAverage {
                    if lhs.voteCount == rhs.voteCount {
                        return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
                    }

                    return lhs.voteCount > rhs.voteCount
                }

                return lhs.voteAverage > rhs.voteAverage
            }

        case .newestRelease:
            return movies.sorted {
                Self.releaseDatePrecedes(lhs: $0, rhs: $1, ascending: false)
            }

        case .oldestRelease:
            return movies.sorted {
                Self.releaseDatePrecedes(lhs: $0, rhs: $1, ascending: true)
            }
        }
    }

    private static func releaseDatePrecedes(
        lhs: MainMovieListMovieItem,
        rhs: MainMovieListMovieItem,
        ascending: Bool
    ) -> Bool {
        switch (lhs.releaseDate, rhs.releaseDate) {
        case let (.some(lhsDate), .some(rhsDate)) where lhsDate != rhsDate:
            return ascending ? lhsDate < rhsDate : lhsDate > rhsDate

        case (.some, .none):
            return true

        case (.none, .some):
            return false

        default:
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }
}

// MARK: - MainMovieListContent

nonisolated struct MainMovieListContent: Sendable, Equatable {
    let genres: [MainMovieGenreItem]
    let selectedGenre: MainMovieGenreItem
    let movies: [MainMovieListMovieItem]
    let currentPage: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }

    func updatingLoadingNextPage(_ isLoading: Bool) -> MainMovieListContent {
        MainMovieListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            movies: movies,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoading
        )
    }

    func appending(page: MainMovieListMoviePage) -> MainMovieListContent {
        MainMovieListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            movies: movies + page.movies.map(MainMovieListMovieItem.init(movie:)),
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false
        )
    }
}

// MARK: - MainMovieSearchContent

nonisolated struct MainMovieSearchContent: Sendable, Equatable {
    let keyword: String
    let movies: [MainMovieListMovieItem]
    let currentPage: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool
    let selectedFilter: MainMovieSearchFilter

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }

    func updatingLoadingNextPage(_ isLoading: Bool) -> MainMovieSearchContent {
        MainMovieSearchContent(
            keyword: keyword,
            movies: movies,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoading,
            selectedFilter: selectedFilter
        )
    }

    func appending(page: MainMovieSearchResultPage) -> MainMovieSearchContent {
        let appendedMovies = movies + page.movies.map(MainMovieListMovieItem.init(movie:))

        return MainMovieSearchContent(
            keyword: keyword,
            movies: selectedFilter.sorted(appendedMovies),
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false,
            selectedFilter: selectedFilter
        )
    }
}
