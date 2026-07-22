//
//  MemberCenterListModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import Foundation

// MARK: - MemberCenterListViewState

nonisolated enum MemberCenterListViewState: Equatable {
    case idle
    case loading
    case loaded(MemberCenterListContent)
    case empty(MemberCenterDestination)
    case failed(ErrorMessage)
}

// MARK: - MemberCenterListPageResult

nonisolated struct MemberCenterListPageResult: Sendable, Equatable {
    let destination: MemberCenterDestination
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let items: [MemberCenterListItem]
}

// MARK: - MemberCenterListContent

nonisolated struct MemberCenterListContent: Sendable, Equatable {
    let destination: MemberCenterDestination
    let items: [MemberCenterListItem]
    let currentPage: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }

    init(page: MemberCenterListPageResult) {
        self.destination = page.destination
        self.items = page.items
        self.currentPage = page.page
        self.totalPages = page.totalPages
        self.totalResults = page.totalResults
        self.isLoadingNextPage = false
    }

    private init(
        destination: MemberCenterDestination,
        items: [MemberCenterListItem],
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

    func updatingLoadingNextPage(_ isLoading: Bool) -> MemberCenterListContent {
        MemberCenterListContent(
            destination: destination,
            items: items,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoading
        )
    }

    func appending(page: MemberCenterListPageResult) -> MemberCenterListContent {
        MemberCenterListContent(
            destination: page.destination,
            items: items + page.items,
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false
        )
    }
}

// MARK: - MemberCenterListItemDetailTarget

nonisolated enum MemberCenterListItemDetailTarget: Sendable, Equatable {
    case movie(id: Int)
    case tv(id: Int)
    case episode(seriesID: Int, seasonNumber: Int, episodeNumber: Int)
    case list(id: Int)
}

// MARK: - MemberCenterListItem

nonisolated struct MemberCenterListItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let metadataText: String
    let imageURL: URL?
    let detailTarget: MemberCenterListItemDetailTarget

    init(movie: MovieGridMovie, destination: MemberCenterDestination) {
        self.id = "\(destination.rawValue)-movie-\(movie.id)"
        self.title = movie.title
        self.subtitle = BaseDisplayTextFormatter.announcedText(movie.releaseDate)
        self.metadataText = BaseDisplayTextFormatter.ratingText(movie.voteAverage)
        self.imageURL = Self.posterURL(path: movie.posterPath)
        self.detailTarget = .movie(id: movie.id)
    }

    init(series: TVGridSeries, destination: MemberCenterDestination) {
        self.id = "\(destination.rawValue)-tv-\(series.id)"
        self.title = series.name
        self.subtitle = BaseDisplayTextFormatter.announcedText(series.firstAirDate)
        self.metadataText = BaseDisplayTextFormatter.ratingText(series.voteAverage)
        self.imageURL = Self.posterURL(path: series.posterPath)
        self.detailTarget = .tv(id: series.id)
    }

    init(movie: MemberCenterRatedMovie, destination: MemberCenterDestination) {
        self.id = "\(destination.rawValue)-movie-\(movie.id)"
        self.title = movie.title
        self.subtitle = BaseDisplayTextFormatter.announcedText(movie.releaseDate)
        self.metadataText = BaseDisplayTextFormatter.userRatingText(movie.rating)
        self.imageURL = Self.posterURL(path: movie.posterPath)
        self.detailTarget = .movie(id: movie.id)
    }

    init(series: MemberCenterRatedTVSeries, destination: MemberCenterDestination) {
        self.id = "\(destination.rawValue)-tv-\(series.id)"
        self.title = series.name
        self.subtitle = BaseDisplayTextFormatter.announcedText(series.firstAirDate)
        self.metadataText = BaseDisplayTextFormatter.userRatingText(series.rating)
        self.imageURL = Self.posterURL(path: series.posterPath)
        self.detailTarget = .tv(id: series.id)
    }

    init(episode: MemberCenterRatedEpisode, destination: MemberCenterDestination) {
        self.id = "\(destination.rawValue)-episode-\(episode.showID)-\(episode.seasonNumber)-\(episode.episodeNumber)-\(episode.id)"
        self.title = episode.name
        self.subtitle = Self.episodeSubtitle(episode)
        self.metadataText = BaseDisplayTextFormatter.userRatingText(episode.rating)
        self.imageURL = Self.posterURL(path: episode.stillPath)
        self.detailTarget = .episode(
            seriesID: episode.showID,
            seasonNumber: episode.seasonNumber,
            episodeNumber: episode.episodeNumber
        )
    }

    init(list: MemberCenterList, destination: MemberCenterDestination) {
        self.id = "\(destination.rawValue)-list-\(list.id)"
        self.title = list.name
        self.subtitle = list.description.isEmpty ? "沒有描述" : list.description
        self.metadataText = BaseDisplayTextFormatter.countText(list.itemCount, unit: "個項目")
        self.imageURL = Self.posterURL(path: list.posterPath)
        self.detailTarget = .list(id: list.id)
    }

    private static func posterURL(path: String?) -> URL? {
        path.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    private static func episodeSubtitle(_ episode: MemberCenterRatedEpisode) -> String {
        BaseDisplayTextFormatter.metadata([
            BaseDisplayTextFormatter.seasonEpisodeNumberText(
                seasonNumber: episode.seasonNumber,
                episodeNumber: episode.episodeNumber
            ),
            episode.airDate
        ]) ?? ""
    }
}
