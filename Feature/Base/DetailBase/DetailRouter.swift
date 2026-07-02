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
    func showYouTubeVideo(videoKey: String, title: String?)
    func showWebVideo(url: URL, title: String?)
    func openExternalURL(_ url: URL)
}

// MARK: - DetailRouter

@MainActor
final class DetailRouter: DetailRouting {

    // MARK: - DetailPresentation

    private enum DetailPresentation {
        case push
        case present
        case pageSheet(detents: [UISheetPresentationController.Detent])
    }

    // MARK: - Properties

    private weak var sourceViewController: UIViewController?

    // MARK: - Initialization

    init(sourceViewController: UIViewController) {
        self.sourceViewController = sourceViewController
    }

    // MARK: - DetailRouting

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

    func showYouTubeVideo(videoKey: String, title: String?) {
        guard !videoKey.isEmpty else { return }

        let viewController = YouTubePlayerViewController(videoKey: videoKey, title: title)
        show(viewController, using: .pageSheet(detents: [.medium()]))
    }

    func showWebVideo(url: URL, title: String?) {
        show(BaseWebViewController(url: url, title: title), using: .push)
    }

    func openExternalURL(_ url: URL) {
        show(BaseWebViewController(url: url), using: .push)
    }

    // MARK: - Private Methods

    private func show(
        _ viewController: UIViewController,
        using presentation: DetailPresentation
    ) {
        switch presentation {
        case .push:
            sourceViewController?.navigationController?.pushViewController(
                viewController,
                animated: true
            )

        case .present:
            sourceViewController?.present(viewController, animated: true)

        case .pageSheet(let detents):
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.modalPresentationStyle = .pageSheet

            if let sheet = navigationController.sheetPresentationController {
                sheet.detents = detents
                sheet.prefersGrabberVisible = true
            }

            sourceViewController?.present(navigationController, animated: true)
        }
    }
}
