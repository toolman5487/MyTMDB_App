//
//  Review.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - Review

nonisolated struct Review: Sendable, Equatable, Identifiable {
    let id: String
    let authorName: String
    let rating: Double?
    let content: String
    let createdAt: Date?
    let updatedAt: Date?
    let avatarPath: String?

    var isRated: Bool {
        (rating ?? 0) > 0
    }

    var publishedAt: Date? {
        updatedAt ?? createdAt
    }
}

// MARK: - Merging

extension Array where Element == Review {

    func appending(uniqueReviewsFrom newReviews: [Review]) -> [Review] {
        var seenIDs = Set(map(\.id))

        return self + newReviews.filter { review in
            guard !seenIDs.contains(review.id) else { return false }
            seenIDs.insert(review.id)
            return true
        }
    }
}
