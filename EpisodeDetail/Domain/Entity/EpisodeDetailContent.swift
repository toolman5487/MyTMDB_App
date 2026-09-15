//
//  EpisodeDetailContent.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - EpisodeDetailContent

nonisolated struct EpisodeDetailContent: Sendable, Equatable {
    let detail: Episode
    let credits: EpisodeCredits
    let images: EpisodeImages
    let videos: [Video]
    let externalIDs: EpisodeExternalIDs
    let translations: EpisodeTranslations
    let accountState: EpisodeAccountState
    let supportsAccountRating: Bool
}
