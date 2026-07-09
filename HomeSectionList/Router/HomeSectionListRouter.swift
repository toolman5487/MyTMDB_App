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
    func showDetail(for item: MainHomeContentItem)
    func showGenrePageSheet(
        filters: [HomeSectionListGenreItem],
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    )
}

// MARK: - HomeSectionListRouter

@MainActor
final class HomeSectionListRouter: BaseRouter, HomeSectionListRouting {

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

    func showGenrePageSheet(
        filters: [HomeSectionListGenreItem],
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        guard !filters.isEmpty else { return }

        let viewController = MainMovieGenrePageSheetViewController(
            filters: filters.map(MainMovieGenreItem.init(filterItem:)),
            onFilterSelected: onFilterSelected,
            onDismiss: onDismiss
        )
        show(viewController, using: .pageSheet(.medium))
    }
}

// MARK: - Mapping

private extension MainMovieGenreItem {

    init(filterItem: HomeSectionListGenreItem) {
        self.init(
            genre: MainMovieGenre(id: filterItem.id, name: filterItem.name),
            isSelected: filterItem.isSelected
        )
    }
}
