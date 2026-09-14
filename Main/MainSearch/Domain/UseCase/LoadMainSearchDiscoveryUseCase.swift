//
//  LoadMainSearchDiscoveryUseCase.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - LoadMainSearchDiscoveryUseCase

nonisolated protocol LoadMainSearchDiscoveryUseCase: Sendable {
    func callAsFunction() async throws -> MainSearchDiscovery
}

// MARK: - DefaultLoadMainSearchDiscoveryUseCase

nonisolated struct DefaultLoadMainSearchDiscoveryUseCase: LoadMainSearchDiscoveryUseCase {

    // MARK: - Properties

    private let repository: MainSearchProviding

    // MARK: - Initialization

    init(repository: MainSearchProviding) {
        self.repository = repository
    }

    // MARK: - LoadMainSearchDiscoveryUseCase

    func callAsFunction() async throws -> MainSearchDiscovery {
        async let trending = repository.dailyTrending(page: 1)
        async let popularPeople = repository.popularPeople(page: 1)

        return try await MainSearchDiscovery(
            trending: trending,
            popularPeople: popularPeople.items
        )
    }
}
