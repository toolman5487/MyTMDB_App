//
//  LoadMediaListUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - LoadMediaListUseCase

nonisolated protocol LoadMediaListUseCase: Sendable {
    func callAsFunction(
        kind: MediaKind,
        preferredGenreID: Int?,
        sortOrder: MediaSortOrder
    ) async throws -> MediaListSelection?
}

// MARK: - DefaultLoadMediaListUseCase

nonisolated struct DefaultLoadMediaListUseCase: LoadMediaListUseCase {

    // MARK: - Properties

    private let repository: MediaListProviding

    // MARK: - Initialization

    init(repository: MediaListProviding) {
        self.repository = repository
    }

    // MARK: - LoadMediaListUseCase

    func callAsFunction(
        kind: MediaKind,
        preferredGenreID: Int?,
        sortOrder: MediaSortOrder
    ) async throws -> MediaListSelection? {
        let genres = try await repository.genres(kind: kind)

        guard let selectedGenre = selectedGenre(from: genres, preferredID: preferredGenreID) else {
            return nil
        }

        let page = try await repository.discover(
            kind: kind,
            genreID: selectedGenre.id,
            sortOrder: sortOrder,
            page: 1
        )

        return MediaListSelection(
            genres: genres,
            selectedGenre: selectedGenre,
            page: page
        )
    }

    // MARK: - Private Helpers

    private func selectedGenre(from genres: [MediaGenre], preferredID: Int?) -> MediaGenre? {
        if let preferredID,
           let genre = genres.first(where: { $0.id == preferredID }) {
            return genre
        }

        return genres.first
    }
}
