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
    let movies: [MovieGridMovie]
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

// MARK: - MainMovieListContent

nonisolated struct MainMovieListContent: Sendable, Equatable {
    let genres: [MainMovieGenreItem]
    let selectedGenre: MainMovieGenreItem
    let movies: [MovieGridMovieItem]
    let currentPage: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool
    let selectedSortOption: MovieSortOption?

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
        let nextMovies = movies + page.movies.map(MovieGridMovieItem.init(movie:))

        return MainMovieListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            movies: nextMovies,
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false,
            selectedSortOption: selectedSortOption
        )
    }

    func updatingSortOption(_ option: MovieSortOption) -> MainMovieListContent {
        MainMovieListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            movies: movies,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoadingNextPage,
            selectedSortOption: option
        )
    }
}
