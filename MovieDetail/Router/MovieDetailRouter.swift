//
//  MovieDetailRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import UIKit

// MARK: - MovieDetailRouting

@MainActor
protocol MovieDetailRouting: AnyObject {
    func showReviewList()
    func showYouTubeVideo(videoKey: String, title: String?)
    func showWebVideo(url: URL, title: String?)
    func showPersonDetail(personID: Int)
    func showMovieDetail(movieID: Int)
    func showLogin()
}

// MARK: - MovieDetailRouter

@MainActor
final class MovieDetailRouter: BaseRouter, MovieDetailRouting {

    // MARK: - Properties

    private let movieID: Int
    private let detailRouter: DetailRouter

    // MARK: - Initialization

    init(
        sourceViewController: UIViewController,
        movieID: Int
    ) {
        self.movieID = movieID
        self.detailRouter = DetailRouter(sourceViewController: sourceViewController)
        super.init(sourceViewController: sourceViewController)
    }

    // MARK: - Push

    func showReviewList() {
        guard movieID > 0 else { return }
        show(MovieReviewListViewController(movieID: movieID), using: .push)
    }

    func showYouTubeVideo(videoKey: String, title: String?) {
        detailRouter.showYouTubeVideo(videoKey: videoKey, title: title)
    }

    func showWebVideo(url: URL, title: String?) {
        detailRouter.showWebVideo(url: url, title: title)
    }

    func showPersonDetail(personID: Int) {
        detailRouter.showPersonDetail(personID: personID)
    }

    func showMovieDetail(movieID: Int) {
        detailRouter.showMovieDetail(movieID: movieID)
    }

    func showLogin() {
        show(UINavigationController(rootViewController: LoginViewController()), using: .fullScreen)
    }
}
