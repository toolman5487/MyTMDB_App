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
    let accessibilityText: AccessibilityText
    let featuredAccessibilityText: AccessibilityText

    init(summary: MediaSummary, mediaType: MediaKind) {
        let dateText = BaseDisplayTextFormatter.announcedText(
            BaseDisplayTextFormatter.isoDayText(from: summary.releaseDate)
        )
        let scoreText = BaseDisplayTextFormatter.decimal(summary.voteAverage)
        let accessibilityValue = BaseDisplayTextFormatter.metadata([
            mediaType.accessibilityName,
            dateText,
            BaseDisplayTextFormatter.ratingText(scoreText)
        ])

        let title = BaseDisplayTextFormatter.text(summary.title, fallback: "未命名")

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
        self.accessibilityText = AccessibilityText(
            label: title,
            value: accessibilityValue,
            hint: mediaType.accessibilityDetailHint
        )
        self.featuredAccessibilityText = AccessibilityText(
            label: "現正熱映，\(title)",
            value: accessibilityValue,
            hint: mediaType.accessibilityDetailHint
        )
    }
}

// MARK: - HomeCategory Presentation

extension HomeCategory {

    var title: String {
        switch self {
        case .trendingMovies:
            return "今日趨勢電影"

        case .trendingTV:
            return "今日趨勢影集"

        case .popularMovies:
            return "熱門電影"

        case .popularTV:
            return "熱門影集"

        case .nowPlayingMovies:
            return "現正熱映"

        case .onTheAirTV:
            return "播出中影集"

        case .upcomingMovies:
            return "即將上映"

        case .airingTodayTV:
            return "今日播出影集"

        case .topRatedMovies:
            return "高分電影"

        case .topRatedTV:
            return "高分影集"
        }
    }
}

private extension MediaKind {

    var accessibilityName: String {
        switch self {
        case .movie:
            return "電影"

        case .tv:
            return "影集"
        }
    }

    var accessibilityDetailHint: String {
        switch self {
        case .movie:
            return "點兩下開啟電影詳細資料"

        case .tv:
            return "點兩下開啟劇集詳細資料"
        }
    }
}
