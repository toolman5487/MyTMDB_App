//
//  LoadReviewsUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - LoadReviewsUseCase

nonisolated protocol LoadReviewsUseCase: Sendable {
    func callAsFunction(kind: MediaKind, mediaID: Int, page: Int) async throws -> Page<Review>
}

extension LoadReviewsUseCase {

    func callAsFunction(kind: MediaKind, mediaID: Int) async throws -> Page<Review> {
        try await callAsFunction(kind: kind, mediaID: mediaID, page: 1)
    }
}

// MARK: - DefaultLoadReviewsUseCase

nonisolated struct DefaultLoadReviewsUseCase: LoadReviewsUseCase {

    // MARK: - Properties

    private let repository: ReviewProviding

    // MARK: - Initialization

    init(repository: ReviewProviding) {
        self.repository = repository
    }

    // MARK: - LoadReviewsUseCase

    func callAsFunction(
        kind: MediaKind,
        mediaID: Int,
        page: Int = 1
    ) async throws -> Page<Review> {
        guard mediaID > 0 else { throw DomainError.invalidIdentifier(kind) }

        let loadedPage = try await repository.reviews(
            kind: kind,
            mediaID: mediaID,
            page: max(page, 1)
        )

        return Page(
            number: loadedPage.number,
            totalPages: loadedPage.totalPages,
            totalResults: loadedPage.totalResults,
            items: loadedPage.items.filter { !$0.content.isEmpty }
        )
    }
}
