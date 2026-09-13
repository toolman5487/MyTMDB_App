//
//  LoadHomeSectionsUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - LoadHomeSectionsUseCase

nonisolated protocol LoadHomeSectionsUseCase: Sendable {
    func callAsFunction() async throws -> [HomeSection]
}

// MARK: - DefaultLoadHomeSectionsUseCase

nonisolated struct DefaultLoadHomeSectionsUseCase: LoadHomeSectionsUseCase {

    private enum Configuration {
        static let sectionItemLimit = 10
    }

    // MARK: - Properties

    private let repository: HomeContentProviding

    // MARK: - Initialization

    init(repository: HomeContentProviding) {
        self.repository = repository
    }

    // MARK: - LoadHomeSectionsUseCase

    /// 併發載入所有分類，允許部分失敗：只要有任何一個分類成功就回傳成功的部分，
    /// 全部失敗時拋出第一個底層錯誤，讓 Presentation 決定要顯示什麼訊息。
    func callAsFunction() async throws -> [HomeSection] {
        try Task.checkCancellation()

        let repository = self.repository

        let results = try await withThrowingTaskGroup(
            of: HomeSectionLoadResult.self,
            returning: [HomeSectionLoadResult].self
        ) { group in
            for category in HomeCategory.allCases {
                group.addTask(priority: .userInitiated) {
                    do {
                        let page = try await repository.content(category: category, page: 1)
                        return HomeSectionLoadResult.loaded(
                            HomeSection(
                                category: category,
                                totalResults: page.totalResults,
                                items: Array(page.items.prefix(Configuration.sectionItemLimit))
                            )
                        )
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch {
                        try Task.checkCancellation()
                        return HomeSectionLoadResult.failed(category: category, error: error)
                    }
                }
            }

            var completedResults: [HomeSectionLoadResult] = []
            completedResults.reserveCapacity(HomeCategory.allCases.count)

            for try await result in group {
                completedResults.append(result)
            }

            return completedResults
        }

        try Task.checkCancellation()

        let sections = results.compactMap(\.section)
        let failures = results.compactMap(\.failure)

        for failure in failures {
            AppLogger.network.warning(
                "Failed to load home section \(String(describing: failure.category), privacy: .public): \(String(describing: failure.error), privacy: .public)"
            )
        }

        if sections.isEmpty, let firstFailure = failures.first {
            throw firstFailure.error
        }

        return sections
    }
}

// MARK: - HomeSectionLoadResult

private nonisolated enum HomeSectionLoadResult: Sendable {
    case loaded(HomeSection)
    case failed(category: HomeCategory, error: any Error)

    var section: HomeSection? {
        guard case .loaded(let section) = self else { return nil }
        return section
    }

    var failure: (category: HomeCategory, error: any Error)? {
        guard case .failed(let category, let error) = self else { return nil }
        return (category, error)
    }
}
