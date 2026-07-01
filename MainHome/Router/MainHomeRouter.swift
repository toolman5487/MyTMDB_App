//
//  MainHomeRouter.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import UIKit

// MARK: - MainHomeRouting

@MainActor
protocol MainHomeRouting {
    func showDetail(for item: MainHomeContentItem)
}

// MARK: - MainHomeRouter

@MainActor
final class MainHomeRouter: MainHomeRouting {

    // MARK: - Properties

    private weak var sourceViewController: UIViewController?

    // MARK: - Initialization

    init(sourceViewController: UIViewController) {
        self.sourceViewController = sourceViewController
    }

    // MARK: - MainHomeRouting

    func showDetail(for item: MainHomeContentItem) {
        let detailViewController: UIViewController

        switch item.mediaType {
        case .movie:
            detailViewController = MovieDetailViewController(movieID: item.id)

        case .tv:
            detailViewController = TVDetailViewController(seriesID: item.id)
        }

        sourceViewController?.navigationController?.pushViewController(
            detailViewController,
            animated: true
        )
    }
}
