//
//  MovieDetailProviding.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - MovieDetailProviding

nonisolated protocol MovieDetailProviding: Sendable {
    func movie(id: Int) async throws -> Movie
    func credits(movieID: Int) async throws -> MovieCredits
    func videos(movieID: Int) async throws -> [Video]
    func images(movieID: Int) async throws -> MediaImages
    func collection(id: Int) async throws -> MovieCollection
    func recommendations(movieID: Int, page: Int) async throws -> Page<MovieSummary>
    func similar(movieID: Int, page: Int) async throws -> Page<MovieSummary>
    func watchProviders(movieID: Int) async throws -> WatchProviders
}
