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
    func showGenreList(genreID: Int)
    func showCompanyDetail(companyID: Int)
    func showWatchProvider(url: URL, title: String?)
    func showContentList(_ configuration: DetailContentListConfiguration)
    func showImagePreview(imageURLs: [URL], selectedImageURL: URL, title: String?)
    func showRatingPageSheet(
        title: String,
        currentValue: Double?,
        defaultValue: Double,
        onSubmit: @escaping (Double) -> Void,
        onDelete: @escaping () -> Void
    )
    func showLogin()
    func showShareSheet(for url: URL, sourceItem: UIBarButtonItem)
}

// MARK: - MovieDetailRouter

@MainActor
final class MovieDetailRouter: BaseRouter, MovieDetailRouting {

    // MARK: - Properties

    private let movieID: Int
    private let sceneBuilder: DetailSceneBuilding
    private let detailRouter: DetailRouter

    // MARK: - Initialization

    init(
        sourceViewController: UIViewController,
        movieID: Int,
        sceneBuilder: DetailSceneBuilding,
        interfaceLocalization: AppInterfaceLocalization
    ) {
        self.movieID = movieID
        self.sceneBuilder = sceneBuilder
        self.detailRouter = DetailRouter(
            sourceViewController: sourceViewController,
            sceneBuilder: sceneBuilder,
            interfaceLocalization: interfaceLocalization
        )
        super.init(
            sourceViewController: sourceViewController,
            interfaceLocalization: interfaceLocalization
        )
    }

    // MARK: - Push

    func showReviewList() {
        guard movieID > 0 else { return }
        show(
            sceneBuilder.makeReviewListViewController(mediaKind: .movie, mediaID: movieID),
            using: .push
        )
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

    func showGenreList(genreID: Int) {
        guard genreID > 0 else { return }

        guard let mainTabBarController else {
            return
        }

        mainTabBarController.showMovieGenreList(genreID: genreID)
    }

    func showCompanyDetail(companyID: Int) {
        detailRouter.showCompanyDetail(companyID: companyID)
    }

    func showWatchProvider(url: URL, title: String?) {
        detailRouter.showWebVideo(url: url, title: title)
    }

    func showContentList(_ configuration: DetailContentListConfiguration) {
        detailRouter.showContentList(configuration)
    }

    func showImagePreview(imageURLs: [URL], selectedImageURL: URL, title: String?) {
        detailRouter.showImagePreview(
            imageURLs: imageURLs,
            selectedImageURL: selectedImageURL,
            title: title
        )
    }

    func showRatingPageSheet(
        title: String,
        currentValue: Double?,
        defaultValue: Double,
        onSubmit: @escaping (Double) -> Void,
        onDelete: @escaping () -> Void
    ) {
        detailRouter.showRatingPageSheet(
            title: title,
            currentValue: currentValue,
            defaultValue: defaultValue,
            onSubmit: onSubmit,
            onDelete: onDelete
        )
    }

    func showLogin() {
        detailRouter.showLogin()
    }

    // MARK: - Share

    func showShareSheet(for url: URL, sourceItem: UIBarButtonItem) {
        detailRouter.showShareSheet(for: url, sourceItem: sourceItem)
    }
}
