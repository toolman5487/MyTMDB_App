//
//  TVDetailProviding.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - TVDetailProviding

nonisolated protocol TVDetailProviding: Sendable {
    func series(id: Int) async throws -> TVSeries
    func aggregateCredits(seriesID: Int) async throws -> AggregateCredits
    func videos(seriesID: Int) async throws -> [Video]
    func images(seriesID: Int) async throws -> MediaImages
    func recommendations(seriesID: Int, page: Int) async throws -> Page<MediaSummary>
    func similar(seriesID: Int, page: Int) async throws -> Page<MediaSummary>
    func watchProviders(seriesID: Int) async throws -> WatchProviders
}
