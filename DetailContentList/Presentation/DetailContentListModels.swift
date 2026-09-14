//
//  DetailContentListModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/20.
//

import Foundation

// MARK: - DetailContentListConfiguration

nonisolated struct DetailContentListConfiguration: Sendable, Equatable {
    let title: String
    let thumbnailStyle: DetailContentListThumbnailStyle
    let items: [DetailContentListItem]
}

// MARK: - DetailContentListThumbnailStyle

nonisolated enum DetailContentListThumbnailStyle: Sendable, Equatable {
    case portrait
    case landscape
    case gallery
}

// MARK: - DetailContentListItem

nonisolated struct DetailContentListItem: Sendable, Equatable, Identifiable {
    let id: String
    let imageURL: URL?
    let title: String
    let subtitle: String?
    let destination: DetailContentListDestination
}

// MARK: - DetailContentListDestination

nonisolated enum DetailContentListDestination: Sendable, Equatable {
    case movie(id: Int)
    case tv(seriesID: Int)
    case episode(seriesID: Int, seasonNumber: Int, episodeNumber: Int)
    case person(id: Int)
    case youtube(videoKey: String, title: String?)
    case webVideo(url: URL, title: String?)
    case image(url: URL)
    case none
}

// MARK: - Accessibility

extension DetailContentListItem {

    var accessibilityText: AccessibilityText {
        AccessibilityText(
            label: title,
            value: BaseDisplayTextFormatter.nonEmptyText(subtitle),
            hint: accessibilityHint
        )
    }

    private var accessibilityHint: String? {
        switch destination {
        case .movie:
            return "點兩下開啟電影詳細資料"

        case .tv:
            return "點兩下開啟劇集詳細資料"

        case .episode:
            return "點兩下開啟單集詳細資料"

        case .person:
            return "點兩下開啟人物詳細資料"

        case .youtube, .webVideo:
            return "點兩下播放影片"

        case .image:
            return "點兩下預覽圖片"

        case .none:
            return nil
        }
    }
}
