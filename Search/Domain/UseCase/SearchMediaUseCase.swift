//
//  SearchMediaUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - SearchMediaUseCase

nonisolated protocol SearchMediaUseCase: Sendable {
    func callAsFunction(kind: MediaKind, keyword: String, page: Int) async throws -> Page<MediaSummary>
}

// MARK: - DefaultSearchMediaUseCase

nonisolated struct DefaultSearchMediaUseCase: SearchMediaUseCase {

    // MARK: - Properties

    private let repository: MediaSearchProviding

    // MARK: - Initialization

    init(repository: MediaSearchProviding) {
        self.repository = repository
    }

    // MARK: - SearchMediaUseCase

    func callAsFunction(
        kind: MediaKind,
        keyword: String,
        page: Int
    ) async throws -> Page<MediaSummary> {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKeyword.isEmpty else { return .empty(number: max(page, 1)) }

        return try await repository.search(
            kind: kind,
            keyword: trimmedKeyword,
            page: max(page, 1)
        )
    }
}
