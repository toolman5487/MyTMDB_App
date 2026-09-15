//
//  TVDetailRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import UIKit

// MARK: - TVDetailRouting

@MainActor
protocol TVDetailRouting: AnyObject {
    func showReviewList()
    func showYouTubeVideo(videoKey: String, title: String?)
    func showWebVideo(url: URL, title: String?)
    func showPersonDetail(personID: Int)
    func showSeasonDetail(seasonNumber: Int)
    func showTVDetail(seriesID: Int)
    func showGenreList(genreID: Int)
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

// MARK: - TVDetailRouter

@MainActor
final class TVDetailRouter: BaseRouter, TVDetailRouting {

    // MARK: - Properties

    private let seriesID: Int
    private let sceneBuilder: DetailSceneBuilding
    private let detailRouter: DetailRouter

    // MARK: - Initialization

    init(
        sourceViewController: UIViewController,
        seriesID: Int,
        sceneBuilder: DetailSceneBuilding
    ) {
        self.seriesID = seriesID
        self.sceneBuilder = sceneBuilder
        self.detailRouter = DetailRouter(
            sourceViewController: sourceViewController,
            sceneBuilder: sceneBuilder
        )
        super.init(sourceViewController: sourceViewController)
    }

    // MARK: - Push

    func showReviewList() {
        guard seriesID > 0 else { return }
        show(
            sceneBuilder.makeReviewListViewController(mediaKind: .tv, mediaID: seriesID),
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

    func showSeasonDetail(seasonNumber: Int) {
        detailRouter.showSeasonDetail(
            seriesID: seriesID,
            seasonNumber: seasonNumber
        )
    }

    func showTVDetail(seriesID: Int) {
        detailRouter.showTVDetail(seriesID: seriesID)
    }

    func showGenreList(genreID: Int) {
        guard genreID > 0 else { return }

        guard let mainTabBarController else {
            return
        }

        mainTabBarController.showTVGenreList(genreID: genreID)
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
