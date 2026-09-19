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

    func accessibilityText(localization: AppInterfaceLocalization) -> AccessibilityText {
        AccessibilityText(
            label: title,
            value: BaseDisplayTextFormatter.nonEmptyText(subtitle),
            hint: accessibilityHint(localization: localization)
        )
    }

    private func accessibilityHint(localization: AppInterfaceLocalization) -> String? {
        switch destination {
        case .movie:
            return MediaKind.movie.detailAccessibilityHint(localization: localization)

        case .tv:
            return MediaKind.tv.detailAccessibilityHint(localization: localization)

        case .episode:
            return localization.string(
                "common.accessibility.open_episode_detail.hint",
                defaultValue: "Double-tap to open episode details"
            )

        case .person:
            return localization.string(
                "common.accessibility.open_person_detail.hint",
                defaultValue: "Double-tap to open person details"
            )

        case .youtube, .webVideo:
            return localization.string(
                "common.accessibility.play_video.hint",
                defaultValue: "Double-tap to play the video"
            )

        case .image:
            return localization.string(
                "common.accessibility.preview_image.hint",
                defaultValue: "Double-tap to preview the image"
            )

        case .none:
            return nil
        }
    }
}
