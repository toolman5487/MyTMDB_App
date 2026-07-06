//
//  MovieSearchModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - MovieSearchResultPage

nonisolated struct MovieSearchResultPage: Sendable, Equatable {
    let keyword: String
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let movies: [MovieGridMovie]
}

// MARK: - MovieSearchContent

nonisolated struct MovieSearchContent: Sendable, Equatable {
    let keyword: String
    let movies: [MovieGridMovieItem]
    let currentPage: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool
    let selectedSortOption: MovieSortOption?

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }

    func updatingLoadingNextPage(_ isLoading: Bool) -> MovieSearchContent {
        MovieSearchContent(
            keyword: keyword,
            movies: movies,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoading,
            selectedSortOption: selectedSortOption
        )
    }

    func appending(page: MovieSearchResultPage) -> MovieSearchContent {
        let nextMovies = movies + page.movies.map(MovieGridMovieItem.init(movie:))

        return MovieSearchContent(
            keyword: keyword,
            movies: selectedSortOption?.sorted(nextMovies) ?? nextMovies,
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false,
            selectedSortOption: selectedSortOption
        )
    }

    func sorting(by option: MovieSortOption) -> MovieSearchContent {
        MovieSearchContent(
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
