//
//  ReviewListRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/14.
//

import UIKit

// MARK: - ReviewListRouting

@MainActor
protocol ReviewListRouting: AnyObject {
    func showReviewDetail(for review: ReviewItem)
}

// MARK: - ReviewListRouter

@MainActor
final class ReviewListRouter: BaseRouter, ReviewListRouting {

    func showReviewDetail(for review: ReviewItem) {
        let title = BaseDisplayTextFormatter.ratingText(review.ratingText) ?? "評論"
        let viewController = ReviewDetailViewController(review: review, title: title)
        show(viewController, using: .pageSheet(.large))
    }
}
