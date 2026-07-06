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

// MARK: - MainMovieListSortOption

nonisolated enum MainMovieListSortOption: CaseIterable, Sendable, Hashable, Identifiable {
    case ratingHighToLow
    case ratingLowToHigh
    case newestRelease
    case oldestRelease
    case titleAscending
    case titleDescending

    var id: MainMovieListSortOption {
        self
    }

    var title: String {
        switch self {
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

    func sorted(_ movies: [MainMovieListMovieItem]) -> [MainMovieListMovieItem] {
        switch self {
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
        _ lhs: MainMovieListMovieItem,
        _ rhs: MainMovieListMovieItem,
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
        _ lhs: MainMovieListMovieItem,
        _ rhs: MainMovieListMovieItem
    ) -> Bool {
        let comparison = lhs.title.localizedStandardCompare(rhs.title)
        if comparison != .orderedSame {
            return comparison == .orderedAscending
        }

        return lhs.id < rhs.id
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
    let selectedSortOption: MainMovieListSortOption?

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
            isLoadingNextPage: isLoading,
            selectedSortOption: selectedSortOption
        )
    }

    func appending(page: MainMovieListMoviePage) -> MainMovieListContent {
        let nextMovies = movies + page.movies.map(MainMovieListMovieItem.init(movie:))

        return MainMovieListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            movies: selectedSortOption?.sorted(nextMovies) ?? nextMovies,
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false,
            selectedSortOption: selectedSortOption
        )
    }

    func sorting(by option: MainMovieListSortOption) -> MainMovieListContent {
        MainMovieListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            movies: option.sorted(movies),
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoadingNextPage,
            selectedSortOption: option
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
    let selectedSortOption: MainMovieListSortOption?

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
            selectedSortOption: selectedSortOption
        )
    }

    func appending(page: MainMovieSearchResultPage) -> MainMovieSearchContent {
        let nextMovies = movies + page.movies.map(MainMovieListMovieItem.init(movie:))

        return MainMovieSearchContent(
            keyword: keyword,
            movies: selectedSortOption?.sorted(nextMovies) ?? nextMovies,
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false,
            selectedSortOption: selectedSortOption
        )
    }

    func sorting(by option: MainMovieListSortOption) -> MainMovieSearchContent {
        MainMovieSearchContent(
            keyword: keyword,
            movies: option.sorted(movies),
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoadingNextPage,
            selectedSortOption: option
        )
    }
}
