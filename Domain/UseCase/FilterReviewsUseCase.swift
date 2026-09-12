//
//  FilterReviewsUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - FilterReviewsUseCase

nonisolated protocol FilterReviewsUseCase: Sendable {
    func callAsFunction(_ reviews: [Review], filter: ReviewFilter) -> [Review]
}

// MARK: - DefaultFilterReviewsUseCase

nonisolated struct DefaultFilterReviewsUseCase: FilterReviewsUseCase {

    // MARK: - FilterReviewsUseCase

    func callAsFunction(_ reviews: [Review], filter: ReviewFilter) -> [Review] {
        switch filter {
        case .all:
            return reviews

        case .rated:
            return reviews.filter(\.isRated)

        case .unrated:
            return reviews.filter { !$0.isRated }

        case .latest:
            return reviews.sorted { isReview($0, orderedBefore: $1, ascending: false) }

        case .oldest:
            return reviews.sorted { isReview($0, orderedBefore: $1, ascending: true) }
        }
    }

    // MARK: - Private Helpers

    private func isReview(
        _ lhs: Review,
        orderedBefore rhs: Review,
        ascending: Bool
    ) -> Bool {
        switch (lhs.publishedAt, rhs.publishedAt) {
        case (.some(let lhsDate), .some(let rhsDate)):
            return ascending ? lhsDate < rhsDate : lhsDate > rhsDate

        case (.some, .none):
            return true

        case (.none, .some):
            return false

        case (.none, .none):
            return lhs.id < rhs.id
        }
    }
}
