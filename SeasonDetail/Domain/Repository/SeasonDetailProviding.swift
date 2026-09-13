//
//  SeasonDetailProviding.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - SeasonDetailProviding

nonisolated protocol SeasonDetailProviding: Sendable {
    func season(seriesID: Int, seasonNumber: Int) async throws -> Season
    func aggregateCredits(seriesID: Int, seasonNumber: Int) async throws -> AggregateCredits
    func credits(seriesID: Int, seasonNumber: Int) async throws -> SeasonCredits
    func images(seriesID: Int, seasonNumber: Int) async throws -> MediaImages
    func videos(seriesID: Int, seasonNumber: Int) async throws -> [Video]
    func watchProviders(seriesID: Int, seasonNumber: Int) async throws -> WatchProviders
    func externalIDs(seriesID: Int, seasonNumber: Int) async throws -> SeasonExternalIDs
    func translations(seriesID: Int, seasonNumber: Int) async throws -> SeasonTranslations
    func accountState(
        seriesID: Int,
        seasonNumber: Int,
        credential: SeasonAccountCredential
    ) async throws -> SeasonAccountState
}
