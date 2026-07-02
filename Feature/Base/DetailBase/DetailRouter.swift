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
    func showMovieDetail(movieID: Int)
    func showTVDetail(seriesID: Int)
    func showPersonDetail(personID: Int)
    func showCreditDetail(_ item: PersonDetailCreditItem)
    func openExternalURL(_ url: URL)
}

// MARK: - DetailRouter

@MainActor
final class DetailRouter: DetailRouting {

    // MARK: - Properties

    private weak var sourceViewController: UIViewController?

    // MARK: - Initialization

    init(sourceViewController: UIViewController) {
        self.sourceViewController = sourceViewController
    }

    // MARK: - DetailRouting

    func showMovieDetail(movieID: Int) {
        guard movieID > 0 else { return }
        push(MovieDetailViewController(movieID: movieID))
    }

    func showTVDetail(seriesID: Int) {
        guard seriesID > 0 else { return }
        push(TVDetailViewController(seriesID: seriesID))
    }

    func showPersonDetail(personID: Int) {
        guard personID > 0 else { return }
        push(PersonDetailViewController(personID: personID))
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

    func openExternalURL(_ url: URL) {
        push(BaseWebViewController(url: url))
    }

    // MARK: - Private Methods

    private func push(_ viewController: UIViewController) {
        sourceViewController?.navigationController?.pushViewController(
            viewController,
            animated: true
        )
    }
}
