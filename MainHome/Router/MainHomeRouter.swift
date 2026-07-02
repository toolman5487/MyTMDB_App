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
final class MainHomeRouter: BaseRouter, MainHomeRouting {

    // MARK: - Push

    func showDetail(for item: MainHomeContentItem) {
        let detailViewController: UIViewController

        switch item.mediaType {
        case .movie:
            detailViewController = MovieDetailViewController(movieID: item.id)

        case .tv:
            detailViewController = TVDetailViewController(seriesID: item.id)
        }

        show(detailViewController, using: .push)
    }
}
