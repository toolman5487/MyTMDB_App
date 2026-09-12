//
//  MovieDetailContent.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - MovieDetailContent

nonisolated struct MovieDetailContent: Sendable, Equatable {
    let movie: Movie
    let credits: MovieCredits
    let videos: [Video]
    let images: MediaImages
    let collection: MovieCollection?
    let recommendations: Page<MediaSummary>
    let similar: Page<MediaSummary>
    let watchProviders: WatchProviders
}
