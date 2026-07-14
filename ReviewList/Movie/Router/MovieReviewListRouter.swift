//
//  MovieReviewListRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/14.
//

import UIKit

// MARK: - MovieReviewListRouting

@MainActor
protocol MovieReviewListRouting: AnyObject {
    func showReviewDetail(for review: MovieDetailReviewItem)
}

// MARK: - MovieReviewListRouter

@MainActor
final class MovieReviewListRouter: BaseRouter, MovieReviewListRouting {

    func showReviewDetail(for review: MovieDetailReviewItem) {
        let title = review.ratingText.map { "評分 \($0)" } ?? "評論"
        let viewController = MovieReviewDetailViewController(review: review, title: title)
        show(viewController, using: .pageSheet(.large))
    }
}
