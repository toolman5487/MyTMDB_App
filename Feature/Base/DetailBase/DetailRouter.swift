//
//  DetailRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/2.
//

import UIKit

// MARK: - DetailRouting

@MainActor
protocol DetailRouting {

    // MARK: Push

    func showMovieDetail(movieID: Int)
    func showTVDetail(seriesID: Int)
    func showPersonDetail(personID: Int)
    func showCreditDetail(_ item: PersonDetailCreditItem)
    func showWebVideo(url: URL, title: String?)
    func openExternalURL(_ url: URL)

    // MARK: Page Sheet

    func showYouTubeVideo(videoKey: String, title: String?)
}

// MARK: - DetailRouter

@MainActor
final class DetailRouter: BaseRouter, DetailRouting {

    // MARK: - Push

    func showMovieDetail(movieID: Int) {
        guard movieID > 0 else { return }
        show(MovieDetailViewController(movieID: movieID), using: .push)
    }

    func showTVDetail(seriesID: Int) {
        guard seriesID > 0 else { return }
        show(TVDetailViewController(seriesID: seriesID), using: .push)
    }

    func showPersonDetail(personID: Int) {
        guard personID > 0 else { return }
        show(PersonDetailViewController(personID: personID), using: .push)
    }

    func showCreditDetail(_ item: PersonDetailCreditItem) {
        switch item.mediaType {
        case .movie:
            showMovieDetail(movieID: item.sourceID)

        case .tv:
            showTVDetail(seriesID: item.sourceID)

        case .unknown:
            return
        }
    }

    func showWebVideo(url: URL, title: String?) {
        show(BaseWebViewController(url: url, title: title), using: .push)
    }

    func openExternalURL(_ url: URL) {
        show(BaseWebViewController(url: url), using: .push)
    }

    // MARK: - Page Sheet

    func showYouTubeVideo(videoKey: String, title: String?) {
        guard !videoKey.isEmpty else { return }

        let viewController = YouTubePlayerViewController(videoKey: videoKey, title: title)
        show(viewController, using: .pageSheet(.medium))
    }
}
