//
//  SeasonDetailContent.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - SeasonDetailContent

nonisolated struct SeasonDetailContent: Sendable, Equatable {
    let detail: Season
    let aggregateCredits: AggregateCredits
    let credits: SeasonCredits
    let images: MediaImages
    let videos: [Video]
    let watchProviders: WatchProviders
    let externalIDs: SeasonExternalIDs
    let translations: SeasonTranslations
    let accountState: SeasonAccountState
}
