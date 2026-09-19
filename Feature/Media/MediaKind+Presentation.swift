//
//  MediaKind+Presentation.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - Display Text

extension MediaKind {

    func displayName(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .movie:
            return localization.string(
                "common.media.movie",
                defaultValue: "Movie"
            )

        case .tv:
            return localization.string(
                "common.media.tv_series",
                defaultValue: "TV Show"
            )
        }
    }

    func detailAccessibilityHint(localization: AppInterfaceLocalization) -> String {
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

    func invalidIdentifierMessage(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .movie:
            return localization.string(
                "common.error.invalid_movie_id.message",
                defaultValue: "The movie ID is invalid. Go back and try again."
            )

        case .tv:
            return localization.string(
                "common.error.invalid_tv_id.message",
                defaultValue: "The TV show ID is invalid. Go back and try again."
            )
        }
    }

    var systemImageName: String {
        switch self {
        case .movie:
            return "film"

        case .tv:
            return "tv"
        }
    }
}
