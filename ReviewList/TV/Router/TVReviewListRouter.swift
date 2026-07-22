//
//  TVReviewListRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/14.
//

import UIKit

// MARK: - TVReviewListRouting

@MainActor
protocol TVReviewListRouting: AnyObject {
    func showReviewDetail(for review: TVReviewDetailItem)
}

// MARK: - TVReviewListRouter

@MainActor
final class TVReviewListRouter: BaseRouter, TVReviewListRouting {

    func showReviewDetail(for review: TVReviewDetailItem) {
        let title = BaseDisplayTextFormatter.ratingText(review.ratingText) ?? "評論"
        let viewController = TVReviewDetailViewController(review: review, title: title)
        show(viewController, using: .pageSheet(.large))
    }
}
