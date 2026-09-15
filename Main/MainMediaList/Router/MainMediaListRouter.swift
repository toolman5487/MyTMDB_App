//
//  MainMediaListRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import UIKit

// MARK: - MainMediaListRouting

@MainActor
protocol MainMediaListRouting: AnyObject {
    var shouldIgnoreSearchCancellation: Bool { get }

    func showMediaDetail(itemID: Int)
    func showMediaDetailFromSearch(
        itemID: Int,
        searchController: UISearchController,
        onSearchDismissed: @escaping () -> Void
    )
    func showGenrePageSheet(
        kind: MediaKind,
        filters: [MainMediaGenreItem],
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    )
}

// MARK: - MainMediaListRouter

@MainActor
final class MainMediaListRouter: BaseRouter, MainMediaListRouting {

    // MARK: - Properties

    private let mediaKind: MediaKind
    private let sceneBuilder: DetailSceneBuilding
    private(set) var isDismissingSearchForNavigation = false

    // MARK: - Initialization

    init(
        sourceViewController: UIViewController,
        mediaKind: MediaKind,
        sceneBuilder: DetailSceneBuilding
    ) {
        self.mediaKind = mediaKind
        self.sceneBuilder = sceneBuilder
        super.init(sourceViewController: sourceViewController)
    }

    var shouldIgnoreSearchCancellation: Bool {
        isDismissingSearchForNavigation
    }

    // MARK: - Push

    func showMediaDetail(itemID: Int) {
        guard itemID > 0 else { return }
        show(makeDetailViewController(itemID: itemID), using: .push)
    }

    func showMediaDetailFromSearch(
        itemID: Int,
        searchController: UISearchController,
        onSearchDismissed: @escaping () -> Void
    ) {
        guard itemID > 0,
              let sourceViewController,
              let navigationController = sourceViewController.navigationController else {
            return
        }

        isDismissingSearchForNavigation = true
        searchController.searchBar.resignFirstResponder()

        let finishSearchCleanup = { [weak self] in
            guard let self else { return }

            if searchController.isActive {
                searchController.isActive = false
            }

            isDismissingSearchForNavigation = false
            onSearchDismissed()
        }

        show(makeDetailViewController(itemID: itemID), using: .push)

        if let transitionCoordinator = navigationController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { [weak self] context in
                guard !context.isCancelled else {
                    self?.isDismissingSearchForNavigation = false
                    return
                }

                finishSearchCleanup()
            }
        } else {
            Task(priority: .userInitiated) { @MainActor in
                finishSearchCleanup()
            }
        }
    }

    // MARK: - Page Sheet

    func showGenrePageSheet(
        kind: MediaKind,
        filters: [MainMediaGenreItem],
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        guard !filters.isEmpty else { return }

        let viewController = MainMediaGenrePageSheetViewController(
            kind: kind,
            filters: filters,
            onFilterSelected: onFilterSelected,
            onDismiss: onDismiss
        )
        show(viewController, using: .pageSheet(.medium))
    }

    // MARK: - Private Helpers

    private func makeDetailViewController(itemID: Int) -> UIViewController {
        switch mediaKind {
        case .movie:
            return sceneBuilder.makeMovieDetailViewController(movieID: itemID)

        case .tv:
            return sceneBuilder.makeTVDetailViewController(seriesID: itemID)
        }
    }
}
