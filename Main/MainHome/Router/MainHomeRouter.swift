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
    func showDetail(for item: HomeContentItem)
    func showSectionList(for category: HomeCategory)
}

// MARK: - MainHomeRouter

@MainActor
final class MainHomeRouter: BaseRouter, MainHomeRouting {

    // MARK: - Properties

    private let sceneBuilder: HomeSceneBuilding

    // MARK: - Initialization

    init(
        sourceViewController: UIViewController,
        sceneBuilder: HomeSceneBuilding,
        interfaceLocalization: AppInterfaceLocalization
    ) {
        self.sceneBuilder = sceneBuilder
        super.init(
            sourceViewController: sourceViewController,
            interfaceLocalization: interfaceLocalization
        )
    }

    // MARK: - MainHomeRouting

    func showDetail(for item: HomeContentItem) {
        let viewController = switch item.mediaType {
        case .movie:
            sceneBuilder.makeMovieDetailViewController(movieID: item.id)

        case .tv:
            sceneBuilder.makeTVDetailViewController(seriesID: item.id)
        }

        show(viewController, using: .push)
    }

    func showSectionList(for category: HomeCategory) {
        show(sceneBuilder.makeHomeSectionListViewController(category: category), using: .push)
    }
}
