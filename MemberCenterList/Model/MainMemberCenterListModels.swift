//
//  MainMemberCenterListModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import Foundation

// MARK: - MainMemberCenterListViewState

nonisolated enum MainMemberCenterListViewState: Equatable {
    case idle
    case loading
    case loaded(MainMemberCenterListContent)
    case empty(MainMemberCenterDestination)
    case failed(ErrorMessage)
}

// MARK: - MainMemberCenterListPageResult

nonisolated struct MainMemberCenterListPageResult: Sendable, Equatable {
    let destination: MainMemberCenterDestination
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let items: [MainMemberCenterListItem]
}

// MARK: - MainMemberCenterListContent

nonisolated struct MainMemberCenterListContent: Sendable, Equatable {
    let destination: MainMemberCenterDestination
    let items: [MainMemberCenterListItem]
    let currentPage: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }

    init(page: MainMemberCenterListPageResult) {
        self.destination = page.destination
        self.items = page.items
        self.currentPage = page.page
        self.totalPages = page.totalPages
        self.totalResults = page.totalResults
        self.isLoadingNextPage = false
    }

    private init(
        destination: MainMemberCenterDestination,
        items: [MainMemberCenterListItem],
        currentPage: Int,
        totalPages: Int,
        totalResults: Int,
        isLoadingNextPage: Bool
    ) {
        self.destination = destination
        self.items = items
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.totalResults = totalResults
        self.isLoadingNextPage = isLoadingNextPage
    }

    func updatingLoadingNextPage(_ isLoading: Bool) -> MainMemberCenterListContent {
        MainMemberCenterListContent(
            destination: destination,
            items: items,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoading
        )
    }

    func appending(page: MainMemberCenterListPageResult) -> MainMemberCenterListContent {
        MainMemberCenterListContent(
            destination: page.destination,
            items: items + page.items,
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false
        )
    }
}

// MARK: - MainMemberCenterListItem

nonisolated struct MainMemberCenterListItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let metadataText: String
    let imageURL: URL?

    init(movie: MovieGridMovie, destination: MainMemberCenterDestination) {
        self.id = "\(destination.rawValue)-movie-\(movie.id)"
        self.title = movie.title
        self.subtitle = Self.dateText(movie.releaseDate)
        self.metadataText = Self.scoreText(movie.voteAverage)
        self.imageURL = Self.posterURL(path: movie.posterPath)
    }

    init(series: TVGridSeries, destination: MainMemberCenterDestination) {
        self.id = "\(destination.rawValue)-tv-\(series.id)"
        self.title = series.name
        self.subtitle = Self.dateText(series.firstAirDate)
        self.metadataText = Self.scoreText(series.voteAverage)
        self.imageURL = Self.posterURL(path: series.posterPath)
    }

    init(movie: MainMemberCenterRatedMovie, destination: MainMemberCenterDestination) {
        self.id = "\(destination.rawValue)-movie-\(movie.id)"
        self.title = movie.title
        self.subtitle = Self.dateText(movie.releaseDate)
        self.metadataText = Self.userRatingText(movie.rating)
        self.imageURL = Self.posterURL(path: movie.posterPath)
    }

    init(series: MainMemberCenterRatedTVSeries, destination: MainMemberCenterDestination) {
        self.id = "\(destination.rawValue)-tv-\(series.id)"
        self.title = series.name
        self.subtitle = Self.dateText(series.firstAirDate)
        self.metadataText = Self.userRatingText(series.rating)
        self.imageURL = Self.posterURL(path: series.posterPath)
    }

    init(episode: MainMemberCenterRatedEpisode, destination: MainMemberCenterDestination) {
        self.id = "\(destination.rawValue)-episode-\(episode.showID)-\(episode.seasonNumber)-\(episode.episodeNumber)-\(episode.id)"
        self.title = episode.name
        self.subtitle = Self.episodeSubtitle(episode)
        self.metadataText = Self.userRatingText(episode.rating)
        self.imageURL = Self.posterURL(path: episode.stillPath)
    }

    init(list: MainMemberCenterList, destination: MainMemberCenterDestination) {
        self.id = "\(destination.rawValue)-list-\(list.id)"
        self.title = list.name
        self.subtitle = list.description.isEmpty ? "沒有描述" : list.description
        self.metadataText = "\(list.itemCount) 個項目"
        self.imageURL = Self.posterURL(path: list.posterPath)
    }

    private static func posterURL(path: String?) -> URL? {
        path.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    private static func dateText(_ value: String?) -> String {
        guard let value, !value.isEmpty else {
            return "尚未公布"
        }

        return value
    }

    private static func scoreText(_ value: Double) -> String {
        "評分 \(String(format: "%.1f", value))"
    }

    private static func userRatingText(_ value: Double) -> String {
        "我的評分 \(String(format: "%.1f", value))"
    }

    private static func episodeSubtitle(_ episode: MainMemberCenterRatedEpisode) -> String {
        let episodeText = "第 \(episode.seasonNumber) 季第 \(episode.episodeNumber) 集"
        guard let airDate = episode.airDate, !airDate.isEmpty else {
            return episodeText
        }

        return "\(episodeText) · \(airDate)"
    }
}
