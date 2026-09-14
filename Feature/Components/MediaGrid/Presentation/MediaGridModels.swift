//
//  MediaGridModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - MediaGridItem

nonisolated struct MediaGridItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterURL: URL?
    let dateText: String
    let scoreText: String

    init(summary: MediaSummary) {
        self.id = summary.id
        self.title = summary.title
        self.overview = BaseDisplayTextFormatter.overview(summary.overview)
        self.posterURL = summary.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
        self.dateText = BaseDisplayTextFormatter.announcedText(
            BaseDisplayTextFormatter.isoDayText(from: summary.releaseDate)
        )
        self.scoreText = BaseDisplayTextFormatter.decimal(summary.voteAverage)
    }
}

// MARK: - MediaSortOrder Presentation

extension MediaSortOrder: Identifiable, AppSortMenuOption {

    public var id: MediaSortOrder {
        self
    }

    public var title: String {
        switch self {
        case .popularity:
            return "人氣最高"

        case .ratingHighToLow:
            return "評分最高"

        case .ratingLowToHigh:
            return "評分最低"

        case .newestDate:
            return "最新發布"

        case .oldestDate:
            return "最早發布"

        case .titleAscending:
            return "名稱 (A → Z)"

        case .titleDescending:
            return "名稱 (Z → A)"
        }
    }
}
