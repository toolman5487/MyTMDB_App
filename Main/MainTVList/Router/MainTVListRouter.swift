//
//  MainTVListRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import UIKit

// MARK: - MainTVListRouting

@MainActor
protocol MainTVListRouting: AnyObject {
    var shouldIgnoreSearchCancellation: Bool { get }

    func showTVDetail(seriesID: Int)
    func showTVDetailFromSearch(
        seriesID: Int,
        searchController: UISearchController,
        onSearchDismissed: @escaping () -> Void
    )
    func showGenrePageSheet(
        filters: [MainTVGenreItem],
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    )
}

// MARK: - MainTVListRouter

@MainActor
final class MainTVListRouter: BaseRouter, MainTVListRouting {

    // MARK: - Properties

    private(set) var isDismissingSearchForNavigation = false

    var shouldIgnoreSearchCancellation: Bool {
        isDismissingSearchForNavigation
    }

    // MARK: - Push

    func showTVDetail(seriesID: Int) {
        guard seriesID > 0 else { return }
        show(TVDetailViewController(seriesID: seriesID), using: .push)
    }

    func showTVDetailFromSearch(
        seriesID: Int,
        searchController: UISearchController,
        onSearchDismissed: @escaping () -> Void
    ) {
        guard seriesID > 0,
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

        show(TVDetailViewController(seriesID: seriesID), using: .push)

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
        filters: [MainTVGenreItem],
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        guard !filters.isEmpty else { return }

        let viewController = MainTVGenrePageSheetViewController(
            filters: filters,
            onFilterSelected: onFilterSelected,
            onDismiss: onDismiss
        )
        show(viewController, using: .pageSheet(.medium))
    }
}
