//
//  TVDetailContent.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - TVDetailContent

nonisolated struct TVDetailContent: Sendable, Equatable {
    let series: TVSeries
    let aggregateCredits: AggregateCredits
    let videos: [Video]
    let images: MediaImages
    let recommendations: Page<MediaSummary>
    let similar: Page<MediaSummary>
    let watchProviders: WatchProviders
}
