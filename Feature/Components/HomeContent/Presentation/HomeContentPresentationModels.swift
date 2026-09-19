//
//  HomeContentPresentationModels.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - HomeContentItem

nonisolated struct HomeContentItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let mediaType: MediaKind
    let overview: String
    let posterURL: URL?
    let backdropURL: URL?
    let dateText: String
    let scoreText: String
    let ratingText: String
    let featuredStatusText: String
    let accessibilityText: AccessibilityText
    let featuredAccessibilityText: AccessibilityText

    init(
        summary: MediaSummary,
        mediaType: MediaKind,
        localization: AppInterfaceLocalization
    ) {
        let dateText = BaseDisplayTextFormatter.announcedText(
            BaseDisplayTextFormatter.isoDayText(from: summary.releaseDate),
            localization: localization
        )
        let scoreText = BaseDisplayTextFormatter.decimal(summary.voteAverage)
        let ratingText: String = BaseDisplayTextFormatter.ratingText(
            scoreText,
            localization: localization
        )
        let accessibilityValue = BaseDisplayTextFormatter.metadata([
            mediaType.accessibilityName(localization: localization),
            dateText,
            ratingText
        ])

        let title = BaseDisplayTextFormatter.text(
            summary.title,
            fallback: localization.string(
                "common.fallback.untitled",
                defaultValue: "Untitled"
            )
        )
        let featuredStatusText = localization.string(
            "home.featured.now_playing",
            defaultValue: "Now Playing"
        )

        self.id = summary.id
        self.title = title
        self.mediaType = mediaType
        self.overview = summary.overview
        self.posterURL = summary.posterPath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w185)
        }
        self.backdropURL = summary.backdropPath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w500)
        }
        self.dateText = dateText
        self.scoreText = scoreText
        self.ratingText = ratingText
        self.featuredStatusText = featuredStatusText
        self.accessibilityText = AccessibilityText(
            label: title,
            value: accessibilityValue,
            hint: mediaType.accessibilityDetailHint(localization: localization)
        )
        self.featuredAccessibilityText = AccessibilityText(
            label: localization.formatted(
                "home.featured.accessibility_label_format",
                defaultValue: "Now playing, %@",
                title
            ),
            value: accessibilityValue,
            hint: mediaType.accessibilityDetailHint(localization: localization)
        )
    }
}

// MARK: - HomeCategory Presentation

extension HomeCategory {

    func title(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .trendingMovies:
            return localization.string("home.category.trending_movies", defaultValue: "Trending Movies Today")

        case .trendingTV:
            return localization.string("home.category.trending_tv", defaultValue: "Trending TV Today")

        case .popularMovies:
            return localization.string("home.category.popular_movies", defaultValue: "Popular Movies")

        case .popularTV:
            return localization.string("home.category.popular_tv", defaultValue: "Popular TV Shows")

        case .nowPlayingMovies:
            return localization.string("home.category.now_playing_movies", defaultValue: "Now Playing")

        case .onTheAirTV:
            return localization.string("home.category.on_the_air_tv", defaultValue: "TV Shows on the Air")

        case .upcomingMovies:
            return localization.string("home.category.upcoming_movies", defaultValue: "Upcoming Movies")

        case .airingTodayTV:
            return localization.string("home.category.airing_today_tv", defaultValue: "TV Airing Today")

        case .topRatedMovies:
            return localization.string("home.category.top_rated_movies", defaultValue: "Top Rated Movies")

        case .topRatedTV:
            return localization.string("home.category.top_rated_tv", defaultValue: "Top Rated TV Shows")
        }
    }
}

private extension MediaKind {

    func accessibilityName(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .movie:
            return localization.string("common.media.movie", defaultValue: "Movie")

        case .tv:
            return localization.string("common.media.tv_series", defaultValue: "TV Show")
        }
    }

    func accessibilityDetailHint(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .movie:
            return localization.string(
                "common.accessibility.open_movie_detail.hint",
                defaultValue: "Double-tap to open movie details"
            )

        case .tv:
            return localization.string(
                "common.accessibility.open_tv_detail.hint",
                defaultValue: "Double-tap to open TV show details"
            )
        }
    }
}
