//
//  MainHomeRouter.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import UIKit

// MARK: - MainHomeRouting

@MainActor
protocol MainHomeRouting: AnyObject {
    func showDetail(for item: MainHomeContentItem)
    func showSectionList(for category: MainHomeContentCategory)
}

// MARK: - MainHomeRouter

@MainActor
final class MainHomeRouter: BaseRouter, MainHomeRouting {

    // MARK: - MainHomeRouting

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

    func showSectionList(for category: MainHomeContentCategory) {
        let viewController = HomeSectionListViewController(category: category)
        show(viewController, using: .push)
    }
}
