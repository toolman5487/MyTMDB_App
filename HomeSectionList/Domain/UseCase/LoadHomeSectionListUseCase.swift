//
//  LoadHomeSectionListUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - LoadHomeSectionListUseCase

nonisolated protocol LoadHomeSectionListUseCase: Sendable {
    func callAsFunction(category: HomeCategory) async throws -> HomeSectionListSelection
}

// MARK: - DefaultLoadHomeSectionListUseCase

nonisolated struct DefaultLoadHomeSectionListUseCase: LoadHomeSectionListUseCase {

    // MARK: - Properties

    private let contentRepository: HomeContentProviding
    private let genreRepository: MediaGenreProviding

    // MARK: - Initialization

    init(
        contentRepository: HomeContentProviding,
        genreRepository: MediaGenreProviding
    ) {
        self.contentRepository = contentRepository
        self.genreRepository = genreRepository
    }

    // MARK: - LoadHomeSectionListUseCase

    func callAsFunction(category: HomeCategory) async throws -> HomeSectionListSelection {
        async let genresTask = genreRepository.genres(kind: category.mediaType)
        async let pageTask = contentRepository.content(category: category, page: 1)

        let (genres, page) = try await (genresTask, pageTask)

        return HomeSectionListSelection(genres: genres, page: page)
    }
}
