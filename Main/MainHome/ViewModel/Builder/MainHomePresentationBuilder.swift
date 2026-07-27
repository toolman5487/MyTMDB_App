//
//  MainHomePresentationBuilder.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation

// MARK: - MainHomePresentationBuilder

nonisolated enum MainHomePresentationBuilder {

    static func makeSections(from sections: [MainHomeContentSection]) -> [MainHomeSectionItem] {
        sections
            .filter { !$0.contents.isEmpty }
            .sorted { lhs, rhs in
                lhs.category.displayPriority < rhs.category.displayPriority
            }
            .map(MainHomeSectionItem.init(section:))
    }
}

// MARK: - MainHomeSectionItem

nonisolated struct MainHomeSectionItem: Sendable, Equatable, Identifiable {
    let id: MainHomeContentCategory
    let category: MainHomeContentCategory
    let title: String
    let contents: [MainHomeContentItem]

    init(section: MainHomeContentSection) {
        self.id = section.category
        self.category = section.category
        self.title = section.category.title
        self.contents = section.contents.map { content in
            MainHomeContentItem(
                content: content,
                mediaType: section.category.mediaType
            )
        }
    }
}

// MARK: - MainHomeContentItem

nonisolated struct MainHomeContentItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let mediaType: MainHomeMediaType
    let overview: String
    let posterURL: URL?
    let backdropURL: URL?
    let dateText: String
    let scoreText: String
    let genreIDs: [Int]
    let accessibilityText: AccessibilityText
    let featuredAccessibilityText: AccessibilityText

    init(content: MainHomeContent, mediaType: MainHomeMediaType) {
        let dateText = BaseDisplayTextFormatter.announcedText(content.primaryDate)
        let scoreText = BaseDisplayTextFormatter.decimal(content.voteAverage)
        let accessibilityValue = BaseDisplayTextFormatter.metadata([
            mediaType.accessibilityName,
            dateText,
            BaseDisplayTextFormatter.ratingText(scoreText)
        ])

        self.id = content.id
        self.title = content.title
        self.mediaType = mediaType
        self.overview = content.overview
        self.posterURL = content.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
        self.backdropURL = content.backdropPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w500)
        }
        self.dateText = dateText
        self.scoreText = scoreText
        self.genreIDs = content.genreIDs
        self.accessibilityText = AccessibilityText(
            label: content.title,
            value: accessibilityValue,
            hint: mediaType.accessibilityDetailHint
        )
        self.featuredAccessibilityText = AccessibilityText(
            label: "現正熱映，\(content.title)",
            value: accessibilityValue,
            hint: mediaType.accessibilityDetailHint
        )
    }
}

// MARK: - MainHomeContentCategory Presentation

extension MainHomeContentCategory {

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

private extension MainHomeMediaType {

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

private extension MainHomeContentCategory {

    var displayPriority: Int {
        switch self {
        case .upcomingMovies:
            return 0

        case .nowPlayingMovies:
            return 1

        case .trendingMovies:
            return 2

        case .popularMovies:
            return 3

        case .topRatedMovies:
            return 4

        case .trendingTV:
            return 5

        case .popularTV:
            return 6

        case .onTheAirTV:
            return 7

        case .airingTodayTV:
            return 8

        case .topRatedTV:
            return 9
        }
    }
}
