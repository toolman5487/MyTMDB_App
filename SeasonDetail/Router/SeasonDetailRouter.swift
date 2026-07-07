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
    func showYouTubeVideo(videoKey: String, title: String?)
    func showWebVideo(url: URL, title: String?)
    func showPersonDetail(personID: Int)
    func showWatchProvider(url: URL, title: String?)
}

// MARK: - SeasonDetailRouter

@MainActor
final class SeasonDetailRouter: BaseRouter, SeasonDetailRouting {

    // MARK: - Properties

    private let detailRouter: DetailRouter

    // MARK: - Initialization

    override init(sourceViewController: UIViewController) {
        self.detailRouter = DetailRouter(sourceViewController: sourceViewController)
        super.init(sourceViewController: sourceViewController)
    }

    // MARK: - Push

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
