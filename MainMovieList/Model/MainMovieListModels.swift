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
    let releaseDateText: String
    let scoreText: String

    init(movie: MainMovieListMovie) {
        self.id = movie.id
        self.title = movie.title
        self.overview = movie.overview.isEmpty ? "目前沒有簡介。" : movie.overview
        self.posterURL = movie.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
        self.releaseDateText = movie.releaseDate?.isEmpty == false ? movie.releaseDate ?? "" : "尚未公布"
        self.scoreText = String(format: "%.1f", movie.voteAverage)
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
            isLoadingNextPage: isLoading
        )
    }

    func appending(page: MainMovieSearchResultPage) -> MainMovieSearchContent {
        MainMovieSearchContent(
            keyword: keyword,
            movies: movies + page.movies.map(MainMovieListMovieItem.init(movie:)),
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false
        )
    }
}
