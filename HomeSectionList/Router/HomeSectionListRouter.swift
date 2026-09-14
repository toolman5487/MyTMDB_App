//
//  HomeSectionListRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import UIKit

// MARK: - HomeSectionListRouting

@MainActor
protocol HomeSectionListRouting: AnyObject {
    func showDetail(for item: HomeContentItem)
    func showGenrePageSheet(
        kind: MediaKind,
        filters: [HomeSectionListGenreItem],
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    )
}

// MARK: - HomeSectionListRouter

@MainActor
final class HomeSectionListRouter: BaseRouter, HomeSectionListRouting {

    // MARK: - Properties

    private let sceneBuilder: DetailSceneBuilding

    // MARK: - Initialization

    init(
        sourceViewController: UIViewController,
        sceneBuilder: DetailSceneBuilding
    ) {
        self.sceneBuilder = sceneBuilder
        super.init(sourceViewController: sourceViewController)
    }

    func showDetail(for item: HomeContentItem) {
        let detailViewController: UIViewController

        switch item.mediaType {
        case .movie:
            detailViewController = sceneBuilder.makeMovieDetailViewController(movieID: item.id)

        case .tv:
            detailViewController = sceneBuilder.makeTVDetailViewController(seriesID: item.id)
        }

        show(detailViewController, using: .push)
    }

    func showGenrePageSheet(
        kind: MediaKind,
        filters: [HomeSectionListGenreItem],
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        guard !filters.isEmpty else { return }

        let viewController = MainMediaGenrePageSheetViewController(
            kind: kind,
            filters: filters.map(MainMediaGenreItem.init(filterItem:)),
            onFilterSelected: onFilterSelected,
            onDismiss: onDismiss
        )
        show(viewController, using: .pageSheet(.medium))
    }
}

// MARK: - Mapping

private extension MainMediaGenreItem {

    init(filterItem: HomeSectionListGenreItem) {
        self.init(
            genre: MediaGenre(id: filterItem.id, name: filterItem.name),
            isSelected: filterItem.isSelected
        )
    }
}
