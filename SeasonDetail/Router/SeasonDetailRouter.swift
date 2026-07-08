//
//  SeasonDetailRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/7.
//

import UIKit

// MARK: - SeasonDetailRouting

@MainActor
protocol SeasonDetailRouting: AnyObject {
    func showEpisodeDetail(episodeNumber: Int)
    func showYouTubeVideo(videoKey: String, title: String?)
    func showWebVideo(url: URL, title: String?)
    func showPersonDetail(personID: Int)
    func showWatchProvider(url: URL, title: String?)
}

// MARK: - SeasonDetailRouter

@MainActor
final class SeasonDetailRouter: BaseRouter, SeasonDetailRouting {

    // MARK: - Properties

    private let seriesID: Int
    private let seasonNumber: Int
    private let detailRouter: DetailRouter

    // MARK: - Initialization

    init(
        sourceViewController: UIViewController,
        seriesID: Int,
        seasonNumber: Int
    ) {
        self.seriesID = seriesID
        self.seasonNumber = seasonNumber
        self.detailRouter = DetailRouter(sourceViewController: sourceViewController)
        super.init(sourceViewController: sourceViewController)
    }

    // MARK: - Push

    func showEpisodeDetail(episodeNumber: Int) {
        detailRouter.showEpisodeDetail(
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber
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

    func showWatchProvider(url: URL, title: String?) {
        detailRouter.showWebVideo(url: url, title: title)
    }
}
