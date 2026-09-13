//
//  EpisodeDetailProviding.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - EpisodeDetailProviding

nonisolated protocol EpisodeDetailProviding: Sendable {
    func episode(input: EpisodeDetailInput) async throws -> Episode
    func credits(input: EpisodeDetailInput) async throws -> EpisodeCredits
    func images(input: EpisodeDetailInput) async throws -> EpisodeImages
    func videos(input: EpisodeDetailInput) async throws -> [Video]
    func externalIDs(input: EpisodeDetailInput) async throws -> EpisodeExternalIDs
    func translations(input: EpisodeDetailInput) async throws -> EpisodeTranslations
    func accountState(
        input: EpisodeDetailInput,
        credential: EpisodeAccountCredential
    ) async throws -> EpisodeAccountState
}
